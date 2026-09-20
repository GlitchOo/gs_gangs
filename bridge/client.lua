-- Client framework bridge

local Core

if Config.Framework == 'vorp' then
	Core = exports.vorp_core:GetCore()
else
	Core = exports['rsg-core']:GetCoreObject()
end

---Show a right tip / short notify.
---@param msg string
---@param duration? number
function NotifyTip(msg, duration)
	duration = duration or 4000
	if Config.Framework == 'vorp' then
		Core.NotifyRightTip(msg, duration)
		return
	end
	Core.Functions.Notify('Gang', msg, 'inform', duration)
end

---Display name for a nearby player (invite list / blips).
---@param serverId number
---@return string
function NearbyPlayerLabel(serverId)
	if Config.Framework == 'vorp' then
		local character = Player(serverId).state.Character
		if character?.FirstName and character?.LastName then
			return ('%s %s'):format(character.FirstName, character.LastName)
		end
		if character?.NickName and character.NickName ~= '' then
			return character.NickName
		end
		return _('player_id', serverId)
	end

	local players = GetActivePlayers()
	for i = 1, #players do
		if GetPlayerServerId(players[i]) == serverId then
			local name = GetPlayerName(players[i])
			if name and name ~= '' then
				return name
			end
			break
		end
	end
	return _('player_id', serverId)
end

---Blip label for a nearby gang member.
---@param serverId number
---@return string
function MemberBlipName(serverId)
	if Config.Framework == 'vorp' then
		local nick = Player(serverId).state.Character?.NickName
		if nick and nick ~= '' then return nick end
	end
	return NearbyPlayerLabel(serverId)
end

---Rebuild Config.Gangs from RSG Shared.Gangs (client mirror).
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

if Config.Framework == 'rsg' then
	CreateThread(function()
		Config.Gangs = NormalizeSharedGangs(Core.Shared.Gangs)
		DevPrint('RSG gangs loaded (client)', json.encode(Config.Gangs))
	end)

	RegisterNetEvent('RSGCore:Client:OnSharedUpdate', function(tableName, key, value)
		if tableName ~= 'Gangs' then return end
		if key and value ~= nil then
			Core.Shared.Gangs[key] = value
		elseif key and value == nil then
			Core.Shared.Gangs[key] = nil
		end
		Config.Gangs = NormalizeSharedGangs(Core.Shared.Gangs)
	end)

	RegisterNetEvent('RSGCore:Client:OnSharedUpdateMultiple', function(tableName, values)
		if tableName ~= 'Gangs' or type(values) ~= 'table' then return end
		for key, value in pairs(values) do
			Core.Shared.Gangs[key] = value
		end
		Config.Gangs = NormalizeSharedGangs(Core.Shared.Gangs)
	end)
end
