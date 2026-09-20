local PendingInvites = {}

local function PlayerLoaded(source, character)
	if not character?.charIdentifier then return end

	local PlayerGang = GetPlayerGang(source)
	if PlayerGang then
		DevPrint(('Player %s %s is in gang %s'):format(character.firstname, character.lastname, PlayerGang.name))
		SetGangState(source, PlayerGang.name, PlayerGang.rank)
	else
		SetGangState(source, nil)
		-- VORP: clear invalid gang key still stored in DB
		if Config.Framework == 'vorp' then
			local raw = MySQL.scalar.await('SELECT gang FROM characters WHERE charidentifier = ?', { character.charIdentifier })
			local gang = json.decode(raw or 'null')
			if gang and gang.name and not Config.Gangs[gang.name] then
				MySQL.execute('UPDATE characters SET gang = ? WHERE charidentifier = ?', {
					json.encode({ name = false, rank = 0, lastupdate = os.time() }),
					character.charIdentifier,
				})
			end
		end
	end

	if HasStaff(source, character) then
		TriggerClientEvent('chat:addSuggestion', source, ('/%s'):format(Config.Commands.staff.set), _('staff_cmd_help'), {
			{ name = 'id', help = _('staff_cmd_id') },
			{ name = 'gang', help = _('staff_cmd_gang') },
			{ name = 'rank', help = _('staff_cmd_rank') },
		})

		TriggerClientEvent('chat:addSuggestion', source, ('/%s'):format(Config.Commands.staff.get), _('staff_cmd_help2'), {
			{ name = 'id', help = _('staff_cmd_id') },
		})
	else
		TriggerClientEvent('chat:removeSuggestion', source, ('/%s'):format(Config.Commands.staff.set))
		TriggerClientEvent('chat:removeSuggestion', source, ('/%s'):format(Config.Commands.staff.get))
	end
end

---Response to the recruit event
---@param bool boolean
---@param player number
RegisterNetEvent('gs_gangs:server:recruitResponse', function(bool, player)
	DevPrint(source, 'gs_gangs:server:recruitResponse', bool, player)
	local src = source
	local Character = GetCharacter(src)
	if not Character then return end

	local gangName = PendingInvites[src]
	if not gangName then return end

	PendingInvites[src] = nil

	if bool then
		if CountMembers(gangName) >= Config.MaxMembers then
			return Notify(src, _('max_members'), 'COLOR_RED', 1500)
		end

		local rank = DefaultRecruitRank(gangName)
		if not SetPlayerGang(src, gangName, rank) then
			return Notify(src, _('no_permission'), 'COLOR_RED', 1500)
		end

		Notify(player, _('accepted_invite', Character.firstname, Character.lastname), 'COLOR_GREEN', 1500)
		Notify(src, _('joined_gang', Config.Gangs[gangName].label), 'COLOR_GREEN', 1500)
	else
		Notify(player, _('declined_invite', Character.firstname, Character.lastname), 'COLOR_RED', 1500)
		Notify(src, _('declined_gang'), 'COLOR_RED', 1500)
	end
end)

---Event triggered to recruit a player
---@param target number
RegisterNetEvent('gs_gangs:server:recruit', function(target)
	DevPrint(source, 'gs_gangs:server:recruit', target)
	local src = source

	local Character = GetCharacter(src)
	if not Character then return end

	local targetOnline, targetCharacter = GetOnlineCharacter(target)
	if not targetOnline or not targetCharacter then
		return Notify(src, _('player_not_online'), 'COLOR_RED', 1500)
	end

	local targetPed = GetPlayerPed(target)
	local targetCoords = GetEntityCoords(targetPed)

	local ped = GetPlayerPed(src)
	local coords = GetEntityCoords(ped)

	if #(coords - targetCoords) > Config.MaxInviteDistance then
		return Notify(src, _('player_too_far'), 'COLOR_RED', 1500)
	end

	local InvitedGang = Player(target).state.Gang
	local InvitingGang = GetPlayerGang(src)

	if not Config.Gangs[InvitingGang?.name] then
		return
	end

	if InvitedGang then
		return Notify(src, _('existing_gang'), 'COLOR_RED', 1500)
	end

	if not Config.Gangs[InvitingGang.name]?.ranks[InvitingGang.rank]?.permissionMenu then
		return Notify(src, _('no_permission'), 'COLOR_RED', 1500)
	end

	if CountMembers(InvitingGang.name) >= Config.MaxMembers then
		return Notify(src, _('max_members'), 'COLOR_RED', 1500)
	end

	local lastLeave = GetLeaveCooldown(targetCharacter.charIdentifier)
	if lastLeave > 0 and (os.time() - lastLeave) < Config.Cooldown then
		return Notify(src, _('cooldown'), 'COLOR_RED', 1500)
	end

	PendingInvites[target] = InvitingGang.name

	TriggerClientEvent('gs_gangs:client:recruit', target, InvitingGang.name, src)
	Notify(src, _('invite_success'), 'COLOR_GREEN', 1500)
end)

---Event triggered to change a members rank
---@param charidentifier string|number
---@param rank number
RegisterNetEvent('gs_gangs:server:changeRank', function(charidentifier, rank)
	DevPrint(source, 'gs_gangs:server:changeRank', charidentifier, rank)
	local src = source
	local Character = GetCharacter(src)
	if not Character then return end

	if charidentifier == nil or charidentifier == '' then return end
	rank = tonumber(rank)
	if not rank then return end

	local PlayerGang = GetPlayerGang(src)
	if not Config.Gangs[PlayerGang?.name] then
		return
	end

	if not Config.Gangs[PlayerGang.name]?.ranks[PlayerGang.rank]?.permissionMenu then
		return Notify(src, _('no_permission'), 'COLOR_RED', 1500)
	end

	if not Config.Gangs[PlayerGang.name].ranks[rank] then
		return Notify(src, _('invalid_rank'), 'COLOR_RED', 1500)
	end

	local currGang = GetGangByCharId(charidentifier)
	if not currGang or currGang.name ~= PlayerGang.name then
		return
	end

	if PlayerGang.rank < rank or PlayerGang.rank <= currGang.rank then
		return Notify(src, _('no_permission'), 'COLOR_RED', 1500)
	end

	SetGangByCharId(charidentifier, PlayerGang.name, rank)
	Notify(src, _('rank_changed'), 'COLOR_GREEN', 1500)
end)

---Event triggered to kick a member
---@param charidentifier string|number
RegisterNetEvent('gs_gangs:server:kickMember', function(charidentifier)
	DevPrint(source, 'gs_gangs:server:kickMember', charidentifier)
	local src = source
	local Character = GetCharacter(src)
	if not Character then return end

	if charidentifier == nil or charidentifier == '' then return end

	local PlayerGang = GetPlayerGang(src)
	if not Config.Gangs[PlayerGang?.name] then
		return
	end

	if tostring(Character.charIdentifier) == tostring(charidentifier) then
		return Notify(src, _('cant_kick_self'), 'COLOR_RED', 1500)
	end

	if not Config.Gangs[PlayerGang.name]?.ranks[PlayerGang.rank]?.permissionMenu then
		return Notify(src, _('no_permission'), 'COLOR_RED', 1500)
	end

	local currGang, targetSrc = GetGangByCharId(charidentifier)
	if not currGang or currGang.name ~= PlayerGang.name then
		return
	end

	SetLeaveCooldown(charidentifier)
	local ok, kickedSrc = SetGangByCharId(charidentifier, false, 0)
	if not ok then return end

	local notifySrc = kickedSrc or targetSrc
	if notifySrc then
		Notify(notifySrc, _('kicked', Config.Gangs[PlayerGang.name].label), 'COLOR_RED', 1500)
	end

	Notify(src, _('kicked_member'), 'COLOR_GREEN', 1500)
	TriggerClientEvent('gs_gangs:client:members', src, FetchMembers(PlayerGang.name))
end)

---Event triggered to get the members of a gang
RegisterNetEvent('gs_gangs:server:getMembers', function()
	DevPrint(source, 'gs_gangs:server:getMembers')
	local src = source
	local Character = GetCharacter(src)
	if not Character then return end

	local PlayerGang = GetPlayerGang(src)
	if not Config.Gangs[PlayerGang?.name] then
		return
	end

	TriggerClientEvent('gs_gangs:client:members', src, FetchMembers(PlayerGang.name))
end)

OnPlayerLoaded(PlayerLoaded)

AddEventHandler('onResourceStart', function(resource)
	if resource ~= U.Cache.Resource then return end
	Wait(1000)
	if Config.Framework == 'rsg' then
		RefreshGangsFromShared()
	end
	ForEachLoadedPlayer(PlayerLoaded)
end)

---Event triggered when a player disconnects
AddEventHandler('playerDropped', function()
	DevPrint(source, 'playerDropped')
	PendingInvites[source] = nil
end)

---Block any client side statebag replication
AddStateBagChangeHandler('Gang', '', function(bagName, key, value, source, replicated)
	if not replicated then return end

	if not bagName:find('entity') then
		local owner = GetPlayerFromStateBagName(bagName)
		local state = Player(owner).state
		local curr = state.Gang

		if source ~= 0 then
			DevPrint('Client attempted to change statebag for player', owner)
			SetTimeout(0, function()
				state:set('Gang', curr, true)
			end)
		end
	end
end)

RegisterCommand(Config.Commands.staff.set, function(source, args)
	local src = source
	local Character = GetCharacter(src)
	if not Character then return end

	if not HasStaff(src, Character) then
		return Notify(src, _('no_permission'), 'COLOR_RED', 1500)
	end

	if not args[1] or not args[2] or not args[3] then
		return Notify(src, _('staff_cmd_missing'), 'COLOR_RED', 1500)
	end

	local target = tonumber(args[1])
	local gang = args[2]
	local rank = tonumber(args[3]) or 0

	local targetOnline, targetCharacter = GetOnlineCharacter(target)
	if not targetOnline or not targetCharacter then
		return Notify(src, _('player_not_online'), 'COLOR_RED', 1500)
	end

	if gang ~= 'none' then
		if not Config.Gangs[gang] then
			return Notify(src, _('invalid_gang'), 'COLOR_RED', 1500)
		end

		if not Config.Gangs[gang].ranks[rank] then
			return Notify(src, _('invalid_rank'), 'COLOR_RED', 1500)
		end

		if CountMembers(gang) >= Config.MaxMembers then
			return Notify(src, _('max_members'), 'COLOR_RED', 1500)
		end

		SetPlayerGang(target, gang, rank)
		Notify(src, _('staff_cmd_success', target, Config.Gangs[gang].label), 'COLOR_GREEN', 1500)
		Notify(target, _('staff_cmd_target', Config.Gangs[gang].label), 'COLOR_GREEN', 1500)
	else
		local currGang = Player(target).state.Gang

		if not currGang then
			return Notify(src, _('staff_cmd_no_gang'), 'COLOR_RED', 1500)
		end

		SetLeaveCooldown(targetCharacter.charIdentifier)
		SetPlayerGang(target, false, 0)
		Notify(src, _('staff_cmd_kick_success', target, Config.Gangs[currGang.name].label), 'COLOR_GREEN', 1500)
		Notify(target, _('staff_cmd_kick_target', Config.Gangs[currGang.name].label), 'COLOR_GREEN', 1500)
	end
end, false)

RegisterCommand(Config.Commands.staff.get, function(source, args)
	local src = source
	local Character = GetCharacter(src)
	if not Character then return end

	if not HasStaff(src, Character) then
		return Notify(src, _('no_permission'), 'COLOR_RED', 1500)
	end

	if not args[1] then
		return Notify(src, _('staff_cmd_missing'), 'COLOR_RED', 1500)
	end

	local target = tonumber(args[1])
	local targetOnline = GetOnlineCharacter(target)
	if not targetOnline then
		return Notify(src, _('player_not_online'), 'COLOR_RED', 1500)
	end

	local Gang = Player(target).state.Gang

	if not Gang then
		return Notify(src, _('staff_cmd_no_gang'), 'COLOR_RED', 1500)
	end

	local rank = Gang.rank
	local gang = Gang.name
	local gangDef = Config.Gangs[gang]
	local rankDef = gangDef?.ranks[rank]
	if not gangDef or not rankDef then
		return Notify(src, _('staff_cmd_no_gang'), 'COLOR_RED', 1500)
	end

	NotifyTip(src, _('staff_cmd_get', gangDef.label, gang, rankDef.label, rank), 4000)
end)
