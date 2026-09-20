local GangAccounts = {}

---@param gangName string
---@param rank number
---@param field string
---@return boolean
local function RankHas(gangName, rank, field)
	local r = Config.Gangs[gangName]?.ranks[rank]
	if not r then return false end
	if r[field] ~= nil then return r[field] == true end
	return r.permissionMenu == true
end

---@param account string
---@return number
function GetGangAccount(account)
	return GangAccounts[account] or 0
end

---@param account string
---@param amount number
function AddGangMoney(account, amount)
	amount = math.floor(tonumber(amount) or 0)
	if amount < 1 or type(account) ~= 'string' or account == '' then return end

	GangAccounts[account] = (GangAccounts[account] or 0) + amount
	MySQL.insert(
		'INSERT INTO gs_gang_ledgers (gang_name, amount) VALUES (?, ?) ON DUPLICATE KEY UPDATE amount = VALUES(amount)',
		{ account, GangAccounts[account] }
	)
end

---@param account string
---@param amount number
---@return boolean
function RemoveGangMoney(account, amount)
	amount = math.floor(tonumber(amount) or 0)
	if amount < 1 then return false end

	local bal = GangAccounts[account] or 0
	if bal < amount then return false end

	GangAccounts[account] = bal - amount
	MySQL.update('UPDATE gs_gang_ledgers SET amount = ? WHERE gang_name = ?', {
		GangAccounts[account],
		account,
	})
	return true
end

local function LoadLedgers()
	local rows = MySQL.query.await('SELECT gang_name, amount FROM gs_gang_ledgers', {})
	GangAccounts = {}
	if not rows then return end

	for i = 1, #rows do
		GangAccounts[rows[i].gang_name] = tonumber(rows[i].amount) or 0
	end

	DevPrint('Ledger accounts loaded', json.encode(GangAccounts))
end

---@param src number
---@return table|nil gang, table|nil character
local function GetPlayerGangData(src)
	local Character = GetCharacter(src)
	if not Character then return nil end

	local PlayerGang = GetPlayerGang(src)
	if not PlayerGang then return nil end

	return PlayerGang, Character
end

---@param account string
---@param amount number
---@param entryType 'deposit'|'withdraw'
---@param character table
local function LogLedgerEntry(account, amount, entryType, character)
	local name = ('%s %s'):format(character.firstname or '', character.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
	if name == '' then name = 'Unknown' end

	local charId = character.charIdentifier
	if type(charId) == 'number' then
		-- keep numeric for VORP; store as string for mixed column
		charId = tostring(charId)
	end

	MySQL.insert(
		'INSERT INTO gs_gang_ledger_logs (gang_name, charidentifier, player_name, entry_type, amount) VALUES (?, ?, ?, ?, ?)',
		{ account, charId, name, entryType, amount }
	)
end

---@param gangName string
---@return table
local function FetchLedgerLog(gangName)
	local limit = math.max(1, tonumber(Config.Ledger?.logLimit) or 12)
	local rows = MySQL.query.await(
		[[
			SELECT player_name, entry_type, amount, UNIX_TIMESTAMP(created_at) AS created_at
			FROM gs_gang_ledger_logs
			WHERE gang_name = ?
			ORDER BY id DESC
			LIMIT ?
		]],
		{ gangName, limit }
	) or {}

	local out = {}
	for i = 1, #rows do
		local row = rows[i]
		out[#out + 1] = {
			player = row.player_name,
			type = row.entry_type,
			amount = tonumber(row.amount) or 0,
			at = tonumber(row.created_at) or 0,
		}
	end
	return out
end

---@param src number
---@param PlayerGang table
---@return table
local function BookPayload(src, PlayerGang)
	local members = FetchMembers(PlayerGang.name)
	return {
		balance = GetGangAccount(PlayerGang.name),
		log = FetchLedgerLog(PlayerGang.name),
		members = members,
		perms = {
			deposit = RankHas(PlayerGang.name, PlayerGang.rank, 'permissionLedgerDeposit'),
			withdraw = RankHas(PlayerGang.name, PlayerGang.rank, 'permissionLedgerWithdraw'),
		},
	}
end

RegisterNetEvent('gs_gangs:server:openBook', function()
	local src = source
	local PlayerGang = GetPlayerGangData(src)
	if not PlayerGang then return end

	if not Config.Gangs[PlayerGang.name]?.ranks[PlayerGang.rank]?.permissionMenu then
		return Notify(src, _('no_permission'), 'COLOR_RED', 1500)
	end

	TriggerClientEvent('gs_gangs:client:openBook', src, BookPayload(src, PlayerGang))
end)

RegisterNetEvent('gs_gangs:server:refreshBook', function()
	local src = source
	local PlayerGang = GetPlayerGangData(src)
	if not PlayerGang then return end

	TriggerClientEvent('gs_gangs:client:bookUpdate', src, BookPayload(src, PlayerGang))
end)

RegisterNetEvent('gs_gangs:server:ledgerDeposit', function(amount)
	local src = source
	amount = math.floor(tonumber(amount) or 0)
	if amount < 1 then return end
	if Config.Ledger?.enable == false then return end

	local PlayerGang, Character = GetPlayerGangData(src)
	if not PlayerGang or not Character then return end

	if not RankHas(PlayerGang.name, PlayerGang.rank, 'permissionLedgerDeposit') then
		return Notify(src, _('no_permission'), 'COLOR_RED', 1500)
	end

	if GetMoney(src, Character) < amount then
		return Notify(src, _('ledger_not_enough_cash'), 'COLOR_RED', 1500)
	end

	if not RemoveMoney(src, Character, amount) then
		return Notify(src, _('ledger_not_enough_cash'), 'COLOR_RED', 1500)
	end

	AddGangMoney(PlayerGang.name, amount)
	LogLedgerEntry(PlayerGang.name, amount, 'deposit', Character)
	Notify(src, _('ledger_deposited', amount), 'COLOR_GREEN', 1500)
	TriggerClientEvent('gs_gangs:client:bookUpdate', src, BookPayload(src, PlayerGang))
end)

RegisterNetEvent('gs_gangs:server:ledgerWithdraw', function(amount)
	local src = source
	amount = math.floor(tonumber(amount) or 0)
	if amount < 1 then return end
	if Config.Ledger?.enable == false then return end

	local PlayerGang, Character = GetPlayerGangData(src)
	if not PlayerGang or not Character then return end

	if not RankHas(PlayerGang.name, PlayerGang.rank, 'permissionLedgerWithdraw') then
		return Notify(src, _('no_permission'), 'COLOR_RED', 1500)
	end

	if not RemoveGangMoney(PlayerGang.name, amount) then
		return Notify(src, _('ledger_not_enough_funds'), 'COLOR_RED', 1500)
	end

	if not AddMoney(src, Character, amount) then
		AddGangMoney(PlayerGang.name, amount)
		return Notify(src, _('no_permission'), 'COLOR_RED', 1500)
	end

	LogLedgerEntry(PlayerGang.name, amount, 'withdraw', Character)
	Notify(src, _('ledger_withdrawn', amount), 'COLOR_GREEN', 1500)
	TriggerClientEvent('gs_gangs:client:bookUpdate', src, BookPayload(src, PlayerGang))
end)

CreateThread(function()
	Wait(500)
	LoadLedgers()
end)

exports('GetGangAccount', GetGangAccount)
exports('AddGangMoney', AddGangMoney)
exports('RemoveGangMoney', RemoveGangMoney)
