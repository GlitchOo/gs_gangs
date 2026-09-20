-- Server framework bridge

local Core

---@type table<number, string>
local CurrencyMap = {
	[0] = 'cash',
	[1] = 'gold',
	[2] = 'bloodmoney',
}

if Config.Framework == 'vorp' then
	Core = exports.vorp_core:GetCore()
else
	Core = exports['rsg-core']:GetCoreObject()
end

---Rebuild Config.Gangs from RSG Shared.Gangs.
---@param shared table?
---@return table
local function NormalizeSharedGangs(shared)
	local out = {}
	if type(shared) ~= 'table' then return out end

	for name, data in pairs(shared) do
		if name ~= 'none' and type(data) == 'table' then
			local ranks = {}
			for gradeKey, gradeInfo in pairs(data.grades or {}) do
				local level = tonumber(gradeKey)
				if level ~= nil and type(gradeInfo) == 'table' then
					local isBoss = gradeInfo.isboss == true
					ranks[level] = {
						label = gradeInfo.name or tostring(level),
						permissionMenu = isBoss,
						permissionLedgerDeposit = isBoss,
						permissionLedgerWithdraw = isBoss,
					}
				end
			end
			out[name] = {
				label = data.label or name,
				color = ResolveColor(name, data.color),
				ranks = ranks,
			}
		end
	end
	return out
end

---Refresh Config.Gangs from RSG core (no-op on VORP).
function RefreshGangsFromShared()
	if Config.Framework ~= 'rsg' then return end
	Config.Gangs = NormalizeSharedGangs(Core.Shared.Gangs)
	DevPrint('RSG gangs loaded (server)', json.encode(Config.Gangs))
end

if Config.Framework == 'rsg' then
	RefreshGangsFromShared()
end

---Lowest configured rank index for a gang (recruit default).
---@param gangName string
---@return number
function DefaultRecruitRank(gangName)
	local ranks = Config.Gangs[gangName]?.ranks
	if not ranks then
		return Config.Framework == 'rsg' and 0 or 1
	end

	local lowest
	for id in pairs(ranks) do
		local n = tonumber(id)
		if n ~= nil and (not lowest or n < lowest) then
			lowest = n
		end
	end
	return lowest or (Config.Framework == 'rsg' and 0 or 1)
end

---Active character / player wrapper for gameplay code.
---@param source number
---@return table|nil
function GetCharacter(source)
	if Config.Framework == 'vorp' then
		local User = Core.getUser(source)
		if not User then return nil end
		local Character = User.getUsedCharacter
		if not Character?.charIdentifier then return nil end
		return Character
	end

	local Player = Core.Functions.GetPlayer(source)
	if not Player then return nil end
	local pd = Player.PlayerData
	return {
		charIdentifier = pd.citizenid,
		firstname = pd.charinfo?.firstname or '',
		lastname = pd.charinfo?.lastname or '',
		group = nil,
		_player = Player,
		_source = source,
	}
end

---Whether source has a loaded character.
---@param source number
---@return boolean
function HasPlayer(source)
	return GetCharacter(source) ~= nil
end

---Notify with color (VORP advanced / RSG ox_lib style).
---@param source number
---@param msg string
---@param color? string COLOR_RED / COLOR_GREEN
---@param duration? number
function Notify(source, msg, color, duration)
	duration = duration or 1500
	if Config.Framework == 'vorp' then
		Core.NotifyAvanced(source, msg, 'BLIPS', 'blip_mission_camp', color or 'COLOR_WHITE', duration)
		return
	end

	local notifyType = 'inform'
	if color == 'COLOR_RED' then
		notifyType = 'error'
	elseif color == 'COLOR_GREEN' then
		notifyType = 'success'
	end

	TriggerClientEvent('ox_lib:notify', source, {
		title = 'Gang',
		description = msg,
		type = notifyType,
		duration = duration,
	})
end

---Short tip notify.
---@param source number
---@param msg string
---@param duration? number
function NotifyTip(source, msg, duration)
	duration = duration or 4000
	if Config.Framework == 'vorp' then
		Core.NotifyRightTip(source, msg, duration)
		return
	end
	Notify(source, msg, nil, duration)
end

---Sync Player.state.Gang from membership.
---@param source number
---@param gangName? string|false
---@param rank? number
function SetGangState(source, gangName, rank)
	if (gangName or 'none') == 'none' then
		Player(source).state:set('Gang', nil, true)
		return
	end
	Player(source).state:set('Gang', {
		name = gangName,
		rank = tonumber(rank) or DefaultRecruitRank(gangName),
	}, true)
end

---Gang membership for source from framework storage.
---@param source number
---@return table|nil { name, rank }
function GetPlayerGang(source)
	if Config.Framework == 'vorp' then
		local Character = GetCharacter(source)
		if not Character then return nil end
		local raw = MySQL.scalar.await('SELECT gang FROM characters WHERE charidentifier = ?', { Character.charIdentifier })
		local PlayerGang = json.decode(raw or 'null')
		if not Config.Gangs[PlayerGang?.name] then
			return nil
		end
		return { name = PlayerGang.name, rank = tonumber(PlayerGang.rank) or 0 }
	end

	local Player = Core.Functions.GetPlayer(source)
	local data = Player?.PlayerData?.gang
	if (data?.name or 'none') == 'none' then return nil end
	if not Config.Gangs[data.name] then return nil end
	return {
		name = data.name,
		rank = tonumber(data.grade?.level) or 0,
	}
end

---Set gang for an online player. name false/'none' clears membership.
---@param source number
---@param gangName string|false
---@param rank? number
---@return boolean
function SetPlayerGang(source, gangName, rank)
	if Config.Framework == 'vorp' then
		local Character = GetCharacter(source)
		if not Character then return false end
		if (gangName or 'none') == 'none' then
			MySQL.update.await('UPDATE characters SET gang = ? WHERE charidentifier = ?', {
				json.encode({ name = false, rank = 0, lastupdate = os.time() }),
				Character.charIdentifier,
			})
			SetGangState(source, nil)
			return true
		end
		MySQL.update.await('UPDATE characters SET gang = ? WHERE charidentifier = ?', {
			json.encode({ name = gangName, rank = rank, lastupdate = os.time() }),
			Character.charIdentifier,
		})
		SetGangState(source, gangName, rank)
		return true
	end

	local Player = Core.Functions.GetPlayer(source)
	if not Player then return false end
	if (gangName or 'none') == 'none' then
		if not Player.Functions.SetGang('none', '0') then return false end
		SetGangState(source, nil)
		return true
	end
	if not Player.Functions.SetGang(gangName, tostring(rank or 0)) then return false end
	SetGangState(source, gangName, rank)
	return true
end

---Find online player source by character / citizen id.
---@param charId string|number
---@return number|nil source
function GetSourceByCharId(charId)
	if Config.Framework == 'vorp' then
		local id = tonumber(charId)
		if not id then return nil end
		local targetUser = Core.getUserByCharId(id)
		return targetUser?.source
	end

	local Player = Core.Functions.GetPlayerByCitizenId(tostring(charId))
	return Player?.PlayerData?.source
end

---Gang data for a character id (online or offline).
---@param charId string|number
---@return table|nil { name, rank }, number|nil source
function GetGangByCharId(charId)
	if Config.Framework == 'vorp' then
		local id = tonumber(charId)
		if not id then return nil end
		local raw = MySQL.scalar.await('SELECT gang FROM characters WHERE charidentifier = ?', { id })
		local PlayerGang = json.decode(raw or 'null')
		if not PlayerGang?.name then return nil end
		local src = GetSourceByCharId(id)
		return { name = PlayerGang.name, rank = tonumber(PlayerGang.rank) or 0 }, src
	end

	local cid = tostring(charId)
	local Player = Core.Functions.GetPlayerByCitizenId(cid) or Core.Functions.GetOfflinePlayerByCitizenId(cid)
	if not Player then return nil end

	local data = Player.PlayerData.gang
	local src = (not Player.Offline) and Player.PlayerData.source or nil
	if (data?.name or 'none') == 'none' then return nil, src end
	return {
		name = data.name,
		rank = tonumber(data.grade?.level) or 0,
	}, src
end

---Set gang by character / citizen id (online or offline).
---@param charId string|number
---@param gangName string|false
---@param rank? number
---@return boolean, number|nil source
function SetGangByCharId(charId, gangName, rank)
	if Config.Framework == 'vorp' then
		local src = GetSourceByCharId(charId)
		if src then
			return SetPlayerGang(src, gangName, rank), src
		end

		local id = tonumber(charId)
		if not id then return false end
		if (gangName or 'none') == 'none' then
			MySQL.update.await('UPDATE characters SET gang = ? WHERE charidentifier = ?', {
				json.encode({ name = false, rank = 0, lastupdate = os.time() }),
				id,
			})
		else
			MySQL.update.await('UPDATE characters SET gang = ? WHERE charidentifier = ?', {
				json.encode({ name = gangName, rank = rank, lastupdate = os.time() }),
				id,
			})
		end
		return true
	end

	local cid = tostring(charId)
	local Player = Core.Functions.GetPlayerByCitizenId(cid) or Core.Functions.GetOfflinePlayerByCitizenId(cid)
	if not Player then return false end

	local name = (gangName or 'none') == 'none' and 'none' or gangName
	local grade = name == 'none' and '0' or tostring(rank or 0)
	if not Player.Functions.SetGang(name, grade) then return false end

	if Player.Offline then
		Player.Functions.Save()
		return true
	end

	return true, Player.PlayerData.source
end

---Member count for a gang.
---@param gangName string
---@return number
function CountMembers(gangName)
	if Config.Framework == 'vorp' then
		local total = MySQL.scalar.await(
			'SELECT COUNT(*) FROM characters WHERE JSON_EXTRACT(`gang`, \'$.name\') = ?',
			{ gangName }
		)
		return tonumber(total) or 0
	end

	local total = MySQL.scalar.await(
		[[SELECT COUNT(*) FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(gang, '$.name')) = ?]],
		{ gangName }
	)
	return tonumber(total) or 0
end

---Member rows shaped for the book UI.
---@param gangName string
---@return table
function FetchMembers(gangName)
	if Config.Framework == 'vorp' then
		return MySQL.query.await(
			'SELECT charidentifier, firstname, lastname, gang FROM characters WHERE JSON_EXTRACT(`gang`, \'$.name\') = ?',
			{ gangName }
		) or {}
	end

	local rows = MySQL.query.await(
		[[SELECT citizenid, charinfo, gang FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(gang, '$.name')) = ?]],
		{ gangName }
	) or {}

	local out = {}
	for i = 1, #rows do
		local row = rows[i]
		local charinfo = type(row.charinfo) == 'string' and json.decode(row.charinfo) or row.charinfo
		local gang = type(row.gang) == 'string' and json.decode(row.gang) or row.gang
		out[#out + 1] = {
			charidentifier = row.citizenid,
			firstname = charinfo?.firstname or '',
			lastname = charinfo?.lastname or '',
			gang = {
				name = gang?.name,
				rank = tonumber(gang?.grade?.level) or 0,
			},
		}
	end
	return out
end

---Leave-cooldown unix time for a character id (0 if none).
---@param charId string|number
---@return number
function GetLeaveCooldown(charId)
	if Config.Framework == 'vorp' then
		local id = tonumber(charId)
		if not id then return 0 end
		local raw = MySQL.scalar.await('SELECT gang FROM characters WHERE charidentifier = ?', { id })
		local GangData = json.decode(raw or 'null')
		return tonumber(GangData?.lastupdate) or 0
	end

	local ts = MySQL.scalar.await(
		'SELECT last_leave FROM gs_gang_cooldowns WHERE citizenid = ?',
		{ tostring(charId) }
	)
	return tonumber(ts) or 0
end

---Record leave time for cooldown.
---@param charId string|number
function SetLeaveCooldown(charId)
	local now = os.time()
	if Config.Framework == 'vorp' then
		-- VORP stores lastupdate inside gang JSON on leave via SetPlayerGang / SetGangByCharId
		return
	end
	MySQL.insert.await(
		[[INSERT INTO gs_gang_cooldowns (citizenid, last_leave) VALUES (?, ?)
		ON DUPLICATE KEY UPDATE last_leave = VALUES(last_leave)]],
		{ tostring(charId), now }
	)
end

---Whether source may use staff gang commands.
---@param source number
---@param character table
---@return boolean
function HasStaff(source, character)
	local hasAce = IsPlayerAceAllowed(source, Config.Commands.staff.acePerm)
	if hasAce then return true end
	if Config.Framework == 'vorp' then
		return character.group == Config.Commands.staff.group
	end
	return Core.Functions.HasPermission(source, 'admin') == true
		or Core.Functions.HasPermission(source, 'god') == true
end

---Cash balance for ledger (maps Config.Ledger.currency).
---@param source number
---@param character table
---@return number
function GetMoney(source, character)
	local currency = Config.Ledger?.currency or 0
	if Config.Framework == 'vorp' then
		if currency == 1 then return character.gold or 0 end
		if currency == 2 then return character.rol or 0 end
		return character.money or 0
	end
	local Player = character._player or Core.Functions.GetPlayer(source)
	if not Player then return 0 end
	return Player.Functions.GetMoney(CurrencyMap[currency] or 'cash') or 0
end

---Remove currency for ledger deposit.
---@param source number
---@param character table
---@param amount number
---@return boolean
function RemoveMoney(source, character, amount)
	local currency = Config.Ledger?.currency or 0
	if Config.Framework == 'vorp' then
		character.removeCurrency(currency, amount)
		return true
	end
	local Player = character._player or Core.Functions.GetPlayer(source)
	if not Player then return false end
	return Player.Functions.RemoveMoney(CurrencyMap[currency] or 'cash', amount, 'Gang Ledger') == true
end

---Add currency for ledger withdraw.
---@param source number
---@param character table
---@param amount number
---@return boolean
function AddMoney(source, character, amount)
	local currency = Config.Ledger?.currency or 0
	if Config.Framework == 'vorp' then
		character.addCurrency(currency, amount, 'Gang Ledger')
		return true
	end
	local Player = character._player or Core.Functions.GetPlayer(source)
	if not Player then return false end
	return Player.Functions.AddMoney(CurrencyMap[currency] or 'cash', amount, 'Gang Ledger') == true
end

---Whether target player id is online with a character.
---@param target number
---@return boolean, table|nil character
function GetOnlineCharacter(target)
	local character = GetCharacter(target)
	return character ~= nil, character
end

---Register character-load handler.
---@param handler fun(source: number, character: table)
function OnPlayerLoaded(handler)
	if Config.Framework == 'vorp' then
		AddEventHandler('vorp:SelectedCharacter', function(source, character)
			handler(source, character)
		end)
		return
	end

	RegisterNetEvent('RSGCore:Server:OnPlayerLoaded', function()
		local src = source
		local character = GetCharacter(src)
		if character then handler(src, character) end
	end)
end

---Iterate currently loaded players and run handler.
---@param handler fun(source: number, character: table)
function ForEachLoadedPlayer(handler)
	if Config.Framework == 'vorp' then
		local Users = Core.getUsers()
		for _, v in pairs(Users) do
			if v.usedCharacterId ~= -1 then
				local User = v.GetUser()
				local Character = User.getUsedCharacter
				if Character?.charIdentifier then
					handler(User.source, Character)
				end
			end
		end
		return
	end

	local players = Core.Functions.GetRSGPlayers()
	for src, Player in pairs(players) do
		local character = GetCharacter(src)
		if character then handler(src, character) end
	end
end

-- Keep statebag aligned when any resource calls SetGang
if Config.Framework == 'rsg' then
	AddEventHandler('RSGCore:Server:OnGangUpdate', function(src, gang)
		if (gang?.name or 'none') == 'none' then
			SetGangState(src, nil)
			return
		end
		SetGangState(src, gang.name, gang.grade?.level)
	end)

	AddEventHandler('RSGCore:Server:UpdateObject', function()
		Core = exports['rsg-core']:GetCoreObject()
		RefreshGangsFromShared()
	end)
end
