local BookOpen = false
local Core = exports.vorp_core:GetCore()

---Locale table for the book NUI.
---@return table
local function BookLocale()
	return {
		ledger_balance = _('ledger_balance'),
		ledger_balance_desc = _('ledger_balance_desc'),
		ledger_balance_hint = _('ledger_balance_hint'),
		ledger_balance_line = _('ledger_balance_line'),
		ledger_log = _('ledger_log'),
		ledger_log_empty = _('ledger_log_empty'),
		ledger_log_deposit = _('ledger_log_deposit'),
		ledger_log_withdraw = _('ledger_log_withdraw'),
		manage_ledger = _('manage_ledger'),
		manage_ledger_desc = _('manage_ledger_desc'),
		manage_ledger_pick = _('manage_ledger_pick'),
		manage_gang = _('manage_gang'),
		manage_gang_desc = _('manage_gang_desc'),
		manage_gang_pick = _('manage_gang_pick'),
		members = _('members'),
		members_desc = _('members_desc'),
		members_empty = _('members_empty'),
		member_ranks_desc = _('member_ranks_desc'),
		invite = _('invite'),
		invite_desc = _('invite_desc'),
		deposit = _('deposit'),
		deposit_desc = _('deposit_desc'),
		withdraw = _('withdraw'),
		withdraw_desc = _('withdraw_desc'),
		amount = _('amount'),
		wars = _('wars'),
		wars_desc = _('wars_desc'),
		invite_none_nearby = _('invite_none_nearby'),
		invite_player_desc = _('invite_player_desc'),
		invite_already_in_gang = _('invite_already_in_gang'),
		manage = _('manage'),
		change_rank = _('change_rank'),
		rank_current = _('rank_current'),
		member_subtext = _('member_subtext'),
		kick_member = _('kick_member'),
		back = _('back'),
		close = _('close'),
		no_permission = _('no_permission'),
		no_wars = _('no_wars'),
		at_war = _('at_war'),
		at_peace = _('at_peace'),
		declare_war = _('declare_war'),
		declare_peace = _('declare_peace'),
	}
end

---@param serverId number
---@return string
local function NearbyPlayerLabel(serverId)
	local character = Player(serverId).state.Character
	if character?.FirstName and character?.LastName then
		return ('%s %s'):format(character.FirstName, character.LastName)
	end
	if character?.NickName and character.NickName ~= '' then
		return character.NickName
	end
	return _('player_id', serverId)
end

---Nearby invite targets for the book.
---@return table
local function CollectNearby()
	local myCoords = GetEntityCoords(PlayerPedId())
	local maxDist = Config.MaxInviteDistance or 10
	local out = {}
	local players = GetActivePlayers()

	for i = 1, #players do
		local player = players[i]
		if player ~= U.Cache.PlayerId then
			local ped = GetPlayerPed(player)
			if ped ~= 0 and DoesEntityExist(ped) then
				local dist = #(myCoords - GetEntityCoords(ped))
				if dist <= maxDist then
					local serverId = GetPlayerServerId(player)
					local gang = Player(serverId).state.Gang
					out[#out + 1] = {
						serverId = serverId,
						name = NearbyPlayerLabel(serverId),
						dist = math.floor(dist + 0.5),
						inGang = gang ~= nil,
					}
				end
			end
		end
	end

	return out
end

---Rank list for change-rank UI.
---@param gangName string
---@return table
local function CollectRanks(gangName)
	local ranks = {}
	local def = Config.Gangs[gangName]
	if not def then return ranks end

	for id, rank in pairs(def.ranks) do
		ranks[#ranks + 1] = { id = id, label = rank.label }
	end

	table.sort(ranks, function(a, b)
		return a.id < b.id
	end)

	return ranks
end

---Wars list for the book (requires gs_gangwars).
---@param myGang string
---@return table
local function CollectWarsGangs(myGang)
	local out = {}
	if GetResourceState('gs_gangwars') ~= 'started' then
		return out
	end

	local wars = {}
	local ok, result = pcall(function()
		return exports.gs_gangwars:GetWars()
	end)
	if ok and type(result) == 'table' then
		wars = result
	end

	local warSeconds = 60 * 60 * 2
	if GetResourceState('gs_gangwars') == 'started' then
		-- Timers.war lives in gangwars config; fall back if export missing
		warSeconds = 7200
	end

	local function atWarWith(name)
		if wars[myGang]?[name] then return wars[myGang][name] end
		if wars[name]?[myGang] then return wars[name][myGang] end
		return nil
	end

	local function formatTimer(startedAt)
		if not startedAt then return '' end
		local now = GlobalState['gs_gangwars:time'] or 0
		if now == 0 then return '' end
		local timeLeft = (startedAt + warSeconds) - now
		if timeLeft < 0 then timeLeft = 0 end
		local hours = math.floor(timeLeft / 3600)
		local remaining = timeLeft % 3600
		local minutes = math.floor(remaining / 60)
		local seconds = math.floor(remaining % 60)
		return _('can_declare_peace', hours, minutes, seconds)
	end

	for name, gang in pairs(Config.Gangs) do
		if name ~= myGang then
			local started = atWarWith(name)
			out[#out + 1] = {
				name = name,
				label = gang.label,
				atWar = started ~= nil,
				timer = started and formatTimer(started) or '',
			}
		end
	end

	table.sort(out, function(a, b)
		return a.label < b.label
	end)

	return out
end

---@param members? table
---@param balance? number
---@param perms? table
---@param log? table
local function BuildPayload(members, balance, perms, log)
	local gang = LocalPlayer.state.Gang
	if not gang then return nil end

	local def = Config.Gangs[gang.name]
	if not def then return nil end

	local formatted = {}
	if members then
		for i = 1, #members do
			local m = members[i]
			local g = m.gang
			if type(g) == 'string' then
				g = json.decode(g)
			end
			local rank = g?.rank or 1
			formatted[#formatted + 1] = {
				charidentifier = m.charidentifier,
				firstname = m.firstname,
				lastname = m.lastname,
				rank = rank,
				rankLabel = def.ranks[rank]?.label or '',
			}
		end
	end

	return {
		gangName = gang.name,
		gangLabel = def.label,
		balance = balance or 0,
		log = log or {},
		perms = perms or { deposit = false, withdraw = false },
		members = formatted,
		nearby = CollectNearby(),
		ranks = CollectRanks(gang.name),
		warsGangs = CollectWarsGangs(gang.name),
		locale = BookLocale(),
		section = 'balance',
	}
end

function CloseBookMenu()
	if not BookOpen then return end
	BookOpen = false
	SetNuiFocus(false, false)
	SendNUIMessage({ action = 'close' })
end

---Open the camp ledger book hub.
function OpenBookMenu()
	DevPrint('OpenBookMenu')

	if not LocalPlayer.state.Gang then
		return Core.NotifyRightTip(_('not_in_gang'), 4000)
	end

	local gang = LocalPlayer.state.Gang
	local rank = Config.Gangs[gang.name]?.ranks[gang.rank]
	if not rank?.permissionMenu then
		return Core.NotifyRightTip(_('no_permission'), 4000)
	end

	if BookOpen then
		CloseBookMenu()
	end

	TriggerServerEvent('gs_gangs:server:openBook')
end

---OpenMenu alias used by command / export / interact.
function OpenMenu()
	OpenBookMenu()
end

RegisterNetEvent('gs_gangs:client:openBook', function(data)
	if type(data) ~= 'table' then return end

	local payload = BuildPayload(data.members, data.balance, data.perms, data.log)
	if not payload then return end

	BookOpen = true
	SetNuiFocus(true, true)
	SendNUIMessage({
		action = 'open',
		payload = payload,
	})
end)

RegisterNetEvent('gs_gangs:client:bookUpdate', function(data)
	if not BookOpen or type(data) ~= 'table' then return end

	local payload = BuildPayload(data.members, data.balance, data.perms, data.log)
	if not payload then return end

	SendNUIMessage({
		action = 'update',
		payload = payload,
	})
end)

RegisterNUICallback('close', function(_, cb)
	CloseBookMenu()
	cb({ ok = true })
end)

RegisterNUICallback('deposit', function(data, cb)
	local amount = math.floor(tonumber(data?.amount) or 0)
	if amount > 0 then
		TriggerServerEvent('gs_gangs:server:ledgerDeposit', amount)
	end
	cb({ ok = true })
end)

RegisterNUICallback('withdraw', function(data, cb)
	local amount = math.floor(tonumber(data?.amount) or 0)
	if amount > 0 then
		TriggerServerEvent('gs_gangs:server:ledgerWithdraw', amount)
	end
	cb({ ok = true })
end)

RegisterNUICallback('invite', function(data, cb)
	local serverId = tonumber(data?.serverId)
	if serverId then
		TriggerServerEvent('gs_gangs:server:recruit', serverId)
	end
	cb({ ok = true })
end)

RegisterNUICallback('kickMember', function(data, cb)
	local charId = tonumber(data?.charidentifier)
	if charId then
		TriggerServerEvent('gs_gangs:server:kickMember', charId)
	end
	cb({ ok = true })
end)

RegisterNUICallback('changeRank', function(data, cb)
	local charId = tonumber(data?.charidentifier)
	local rank = tonumber(data?.rank)
	if charId and rank then
		TriggerServerEvent('gs_gangs:server:changeRank', charId, rank)
		SetTimeout(400, function()
			if BookOpen then
				TriggerServerEvent('gs_gangs:server:refreshBook')
			end
		end)
	end
	cb({ ok = true })
end)

RegisterNUICallback('declareWar', function(data, cb)
	local gang = data?.gang
	if type(gang) == 'string' and gang ~= '' then
		TriggerServerEvent('gs_gangwars:server:declareWar', gang)
		SetTimeout(800, function()
			if BookOpen then
				TriggerServerEvent('gs_gangs:server:refreshBook')
			end
		end)
	end
	cb({ ok = true })
end)

RegisterNUICallback('declarePeace', function(data, cb)
	local gang = data?.gang
	if type(gang) == 'string' and gang ~= '' then
		TriggerServerEvent('gs_gangwars:server:declarePeace', gang)
		SetTimeout(800, function()
			if BookOpen then
				TriggerServerEvent('gs_gangs:server:refreshBook')
			end
		end)
	end
	cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == U.Cache.Resource then
		CloseBookMenu()
	end
end)

exports('OpenMenu', OpenMenu)

