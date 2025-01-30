local Core = exports.vorp_core:GetCore()
local PendingInvites = {}

local function PlayerLoaded(source, character)
    local data = MySQL.scalar.await('SELECT gang FROM characters WHERE charidentifier = ?', {character.charIdentifier})
    local gang = json.decode(data)

    if gang and gang.name then
        if Config.Gangs[gang.name] then
            DevPrint(('Player %s %s is in gang %s'):format(character.firstname, character.lastname, gang.name))
            Player(source).state:set('Gang', {
                name = gang.name,
                rank = gang.rank
            }, true)
        else
            Player(source).state.Gang = nil
            gang.name = false
            gang.rank = 0
            gang.lastupdate = os.time()
            MySQL.execute('UPDATE characters SET gang = ? WHERE charidentifier = ?', {json.encode(gang), character.charIdentifier})
        end
    end

    local hasGroup = character.group == Config.Commands.staff.group
    local hasAce = IsPlayerAceAllowed(source, Config.Commands.staff.acePerm)

    if hasGroup or hasAce then
        TriggerClientEvent('chat:addSuggestion', source, ('/%s'):format(Config.Commands.staff.set), _('staff_cmd_help'), {
            { name = 'id', help = _('staff_cmd_id') },
            { name = 'gang', help = _('staff_cmd_gang') },
            { name = 'rank', help = _('staff_cmd_rank') },
        })

        TriggerClientEvent("chat:addSuggestion", source, ('/%s'):format(Config.Commands.staff.get), _('staff_cmd_help2'), {
            { name = 'id', help = _('staff_cmd_id') }
        })
    else
        TriggerClientEvent("chat:removeSuggestion", source, ('/%s'):format(Config.Commands.staff.set))
        TriggerClientEvent("chat:removeSuggestion", source, ('/%s'):format(Config.Commands.staff.get))
    end
end

--- Response to the recruit event
--- @param bool boolean
--- @param player number
RegisterNetEvent('gs_gangs:server:recruitResponse', function(bool, player)
    DevPrint(source, 'gs_gangs:server:recruitResponse', bool, player)
    local src = source
    local User <const> = Core.getUser(src)
    if not User then return end
    local Character <const> = User.getUsedCharacter
    if not Character then return end

    local gangName = PendingInvites[src]

    if not gangName then return end

    if bool then
        PendingInvites[src] = nil

        local total = MySQL.scalar.await('SELECT COUNT(*) FROM characters WHERE JSON_EXTRACT(`gang`, \'$.name\') = ?', {gangName})

        if tonumber(total) >= Config.MaxMembers then
            return Core.NotifyAvanced(src, _('max_members'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
        end

        MySQL.update('UPDATE characters SET gang = ? WHERE charidentifier = ?', {
            json.encode({name = gangName, rank = 1, lastupdate = os.time()}),
            Character.charIdentifier
        }, function()
            Player(src).state:set('Gang', {
                name = gangName,
                rank = 1
            }, true)

            Core.NotifyAvanced(player, _('accepted_invite', Character.firstname, Character.lastname), "BLIPS", "blip_mission_camp", "COLOR_GREEN", 1500)
            Core.NotifyAvanced(src, _('joined_gang', Config.Gangs[gangName].label), "BLIPS", "blip_mission_camp", "COLOR_GREEN", 1500)
        end)
    else
        Core.NotifyAvanced(player, _('declined_invite', Character.firstname, Character.lastname), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
        Core.NotifyAvanced(src, _('declined_gang'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end
end)

--- Event triggered to recruit a player
--- @param target number
RegisterNetEvent("gs_gangs:server:recruit", function(target)
    DevPrint(source, 'gs_gangs:server:recruit', target)
    local src = source

    local User <const> = Core.getUser(src)
    if not User then return end
    local Character <const> = User.getUsedCharacter
    if not Character then return end

    local targetUser <const> = Core.getUser(target)
    if not targetUser then
        return Core.NotifyAvanced(src, _('player_not_online'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    local targetPed = GetPlayerPed(target)
    local targetCoords = GetEntityCoords(targetPed)

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    if #(coords - targetCoords) > Config.MaxInviteDistance then
        return Core.NotifyAvanced(src, _('player_too_far'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    local targetPlayer = Player(target).state
    local InvitedGang = targetPlayer.Gang

    local PlayerGang = MySQL.scalar.await('SELECT gang FROM characters WHERE charidentifier = ?', {Character.charIdentifier})
    local InvitingGang = json.decode(PlayerGang)

    if not InvitingGang or not Config.Gangs[InvitingGang.name] then
        return
    end

    if InvitedGang then
        return Core.NotifyAvanced(src, _('existing_gang'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    if InvitedGang and InvitingGang.name == InvitedGang.name then
        return Core.NotifyAvanced(src, _('same_gang'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    if not Config.Gangs[InvitingGang.name].ranks[InvitingGang.rank].permissionMenu then
        return Core.NotifyAvanced(src, _('no_permission'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    local total = MySQL.scalar.await('SELECT COUNT(*) FROM characters WHERE JSON_EXTRACT(`gang`, \'$.name\') = ?', {InvitingGang.name})

    if tonumber(total) >= Config.MaxMembers then
        return Core.NotifyAvanced(src, _('max_members'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    local GangData = MySQL.scalar.await('SELECT gang FROM characters WHERE charidentifier = ?', {target.state.charIdentifier})
    GangData = json.decode(GangData)

    if GangData?.lastupdate and (os.time() - GangData.lastupdate) < Config.Cooldown then
        return Core.NotifyAvanced(src, _('cooldown'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    PendingInvites[target] = InvitingGang.name

    TriggerClientEvent("gs_gangs:client:recruit", target, InvitingGang.name)
    Core.NotifyAvanced(src, _('invite_success'), "BLIPS", "blip_mission_camp", "COLOR_GREEN", 1500)
end)

--- Event triggered to change a members rank
--- @param charidentifier string
--- @param rank number
RegisterNetEvent('gs_gangs:server:changeRank', function(charidentifier, rank)
    DevPrint(source, 'gs_gangs:server:changeRank', charidentifier, rank)
    local src = source
    local User <const> = Core.getUser(src)
    if not User then return end
    local Character <const> = User.getUsedCharacter
    if not Character then return end

    local PlayerGang = MySQL.scalar.await('SELECT gang FROM characters WHERE charidentifier = ?', {Character.charIdentifier})
    PlayerGang = json.decode(PlayerGang)

    if not PlayerGang or not Config.Gangs[PlayerGang.name] then
        return
    end

    if not Config.Gangs[PlayerGang.name].ranks[PlayerGang.rank].permissionMenu then
        return Core.NotifyAvanced(src, _('no_permission'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    local currGang = MySQL.scalar.await('SELECT `gang` FROM characters WHERE charidentifier = ?', {charidentifier})
    currGang = json.decode(currGang)

    if not currGang then
        return
    end

    if PlayerGang.rank < rank or PlayerGang.rank <= currGang.rank then
        return Core.NotifyAvanced(src, _('no_permission'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    MySQL.update('UPDATE characters SET gang = ? WHERE charidentifier = ?', {
        json.encode({name = PlayerGang.name, rank = rank, lastupdate = os.time()}), 
        charidentifier
    }, function()
        local targetUser <const> = Core.getUserByCharId(charidentifier)
        
        if targetUser then
            Player(targetUser.source).state:set('Gang', {
                name = PlayerGang.name,
                rank = rank
            }, true)
        end

        Core.NotifyAvanced(src, _('rank_changed'), "BLIPS", "blip_mission_camp", "COLOR_GREEN", 1500)
    end)

end)

--- Event triggered to kick a member
--- @param charidentifier string
RegisterNetEvent('gs_gangs:server:kickMember', function(charidentifier)
    DevPrint(source, 'gs_gangs:server:kickMember', charidentifier)
    local src = source
    local User <const> = Core.getUser(src)
    if not User then return end
    local Character <const> = User.getUsedCharacter
    if not Character then return end

    local PlayerGang = MySQL.scalar.await('SELECT gang FROM characters WHERE charidentifier = ?', {Character.charIdentifier})
    PlayerGang = json.decode(PlayerGang)

    if Character.charIdentifier == charidentifier then
        return Core.NotifyAvanced(src, _('cant_kick_self'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    if not PlayerGang or not Config.Gangs[PlayerGang.name] then
        return
    end

    if not Config.Gangs[PlayerGang.name].ranks[PlayerGang.rank].permissionMenu then
        return Core.NotifyAvanced(src, _('no_permission'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    MySQL.update('UPDATE characters SET gang = ? WHERE charidentifier = ?', {
        json.encode({name = false, rank = 0, lastupdate = os.time()}), 
        charidentifier
    }, function()
        local targetUser <const> = Core.getUserByCharId(charidentifier)

        if targetUser then
            Player(targetUser.source).state.Gang = nil
            Core.NotifyAvanced(targetUser.source, _('kicked', Config.Gangs[PlayerGang.name].label), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
        end

        Core.NotifyAvanced(src, _('kicked_member'), "BLIPS", "blip_mission_camp", "COLOR_GREEN", 1500)
        local members = MySQL.query.await('SELECT charidentifier, firstname, lastname, gang FROM characters WHERE JSON_EXTRACT(`gang`, \'$.name\') = ?', {player.Gang.name})
        
        TriggerClientEvent('gs_gangs:client:members', src, members)
    end)
end)

--- Event triggered to get the members of a gang
RegisterNetEvent('gs_gangs:server:getMembers', function()
    DevPrint(source, 'gs_gangs:server:getMembers')
    local src = source
    local User <const> = Core.getUser(src)
    if not User then return end
    local Character <const> = User.getUsedCharacter
    if not Character then return end

    local PlayerGang = MySQL.scalar.await('SELECT gang FROM characters WHERE charidentifier = ?', {Character.charIdentifier})
    PlayerGang = json.decode(PlayerGang)

    if not PlayerGang or not Config.Gangs[PlayerGang.name] then
        return
    end

    MySQL.query('SELECT charidentifier, firstname, lastname, gang FROM characters WHERE JSON_EXTRACT(`gang`, \'$.name\') = ?', {PlayerGang.name}, function(result)
        TriggerClientEvent('gs_gangs:client:members', src, result)
    end)
end)

--- Event triggered when player selects their character
AddEventHandler("vorp:SelectedCharacter", PlayerLoaded)

AddEventHandler('onResourceStart', function(resource)
    if resource == U.Cache.Resource then
        Wait(1000)

        local Users <const> = Core.getUsers()

        for k, v in pairs(Users) do
            local User <const> = v.GetUser()
            local Character <const> = User.getUsedCharacter
            if Character then
                PlayerLoaded(User.source, Character)
            end
        end
    end
end)

--- Event triggered when a player disconnects
AddEventHandler('playerDropped', function()
    DevPrint(source, 'playerDropped')
    PendingInvites[source] = nil
end)

--- Block any client side statebag replication
--- Im not sure this is needed but its possible to change client side statebags
AddStateBagChangeHandler("Gang", "", function(bagName, key, value, source, replicated)
    if not replicated then return end

    if not bagName:find("entity") then
        local owner = GetPlayerFromStateBagName(bagName)
        local state = Player(owner).state
        local curr = state.Gang

        if source ~= 0 then
            DevPrint('Client attempted to change statebag for player', owner)
            -- Reset the statebag
            SetTimeout(0, function()
                state.Gang = curr
            end)
        end
    end
end)

RegisterCommand(Config.Commands.staff.set, function(source, args)
    local src = source
    local User <const> = Core.getUser(src)
    if not User then return end
    local Character <const> = User.getUsedCharacter
    if not Character then return end

    local hasGroup = Character.group == Config.Commands.staff.group
    local hasAce = IsPlayerAceAllowed(src, Config.Commands.staff.acePerm)

    if not hasGroup and not hasAce then
        return Core.NotifyAvanced(src, _('no_permission'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    if not args[1] or not args[2] or not args[3] then
        return Core.NotifyAvanced(src, _('staff_cmd_missing'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    local target = tonumber(args[1])
    local gang = args[2]
    local rank = tonumber(args[3]) or 0

    local targetUser <const> = Core.getUser(target)
    if not targetUser then
        return Core.NotifyAvanced(src, _('player_not_online'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    local targetCharacter <const> = targetUser.getUsedCharacter
    if not targetCharacter then
        return Core.NotifyAvanced(src, _('player_not_online'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    if gang ~= 'none' then
        if not Config.Gangs[gang] then
            return Core.NotifyAvanced(src, _('invalid_gang'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
        end

        if not Config.Gangs[gang].ranks[rank] then
            return Core.NotifyAvanced(src, _('invalid_rank'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
        end

        local total = MySQL.scalar.await('SELECT COUNT(*) FROM characters WHERE JSON_EXTRACT(`gang`, \'$.name\') = ?', {gang})

        if tonumber(total) >= Config.MaxMembers then
            return Core.NotifyAvanced(src, _('max_members'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
        end

        MySQL.update('UPDATE characters SET gang = ? WHERE charidentifier = ?', {
            json.encode({name = gang, rank = rank, lastupdate = os.time()}), 
            targetCharacter.charIdentifier
        }, function()
            Player(target).state:set('Gang', {
                name = gang,
                rank = rank
            }, true)

            Core.NotifyAvanced(src, _('staff_cmd_success', target, Config.Gangs[gang].label), "BLIPS", "blip_mission_camp", "COLOR_GREEN", 1500)
            Core.NotifyAvanced(target, _('staff_cmd_target', Config.Gangs[gang].label), "BLIPS", "blip_mission_camp", "COLOR_GREEN", 1500)
        end)
    else
        local currGang = Player(target).state.Gang

        if not currGang then
            return Core.NotifyAvanced(src, _('staff_cmd_no_gang'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
        end

        MySQL.update('UPDATE characters SET gang = ? WHERE charidentifier = ?', {
            json.encode({name = false, rank = 0, lastupdate = os.time()}), 
            targetCharacter.charIdentifier
        }, function()
            Player(target).state.Gang = nil
            Core.NotifyAvanced(src, _('staff_cmd_kick_success', target, Config.Gangs[currGang.name].label), "BLIPS", "blip_mission_camp", "COLOR_GREEN", 1500)
            Core.NotifyAvanced(target, _('staff_cmd_kick_target', Config.Gangs[currGang.name].label), "BLIPS", "blip_mission_camp", "COLOR_GREEN", 1500)
        end)
    end
end, false)

RegisterCommand(Config.Commands.staff.get, function(source, args)
    local src = source
    local User <const> = Core.getUser(src)
    if not User then return end
    local Character <const> = User.getUsedCharacter
    if not Character then return end

    local hasGroup = Character.group == Config.Commands.staff.group
    local hasAce = IsPlayerAceAllowed(src, Config.Commands.staff.acePerm)

    if not hasGroup and not hasAce then
        return Core.NotifyAvanced(src, _('no_permission'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    if not args[1] then
        return Core.NotifyAvanced(src, _('staff_cmd_missing'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    local target = tonumber(args[1])

    local targetUser <const> = Core.getUser(target)
    if not targetUser then
        return Core.NotifyAvanced(src, _('player_not_online'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    local Gang = Player(target).state.Gang

    if not Gang then
        return Core.NotifyAvanced(src, _('staff_cmd_no_gang'), "BLIPS", "blip_mission_camp", "COLOR_RED", 1500)
    end

    local rank = Gang.rank
    local gang = Gang.name

    Core.NotifyRightTip(src, _('staff_cmd_get', Config.Gangs[gang].label, gang, Config.Gangs[gang].ranks[rank].label, rank), 4000)
end)