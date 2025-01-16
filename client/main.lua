local Core = exports.vorp_core:GetCore()
local MemberBlips = {}

--- Cleanup blips on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == U.Cache.Resource then
        for _, blip in next, MemberBlips do
            RemoveBlip(blip)
        end
    end
end)

--- Open Gang menu
RegisterCommand(Config.Commands.openMenu, function(source, args, rawCommand)
    OpenMenu()
end, false)

--- Check player's gang
RegisterCommand(Config.Commands.checkGang, function(source, args, rawCommand)
    if LocalPlayer.state.Gang and Config.Gangs[LocalPlayer.state.Gang.name] then
        local label = Config.Gangs[LocalPlayer.state.Gang.name].label
        local rankLabel = Config.Gangs[LocalPlayer.state.Gang.name].ranks[LocalPlayer.state.Gang.rank].label
        Core.NotifyRightTip(('%s - %s'):format(label, rankLabel), 4000)
    else
        Core.NotifyRightTip(_('not_in_gang'), 4000)
    end
end, false)

if Config.KeyBind.enable then
    CreateThread(function()
        while true do
            Wait(5)
            if LocalPlayer.state.Gang then
                if IsControlJustReleased(0, Config.KeyBind.openMenu) or IsDisabledControlJustReleased(0, Config.KeyBind.openMenu) then
                    OpenMenu()
                end
            end
        end
    end)
end

if Config.ShowNearbyMembers then
    CreateThread(function()
        while true do
            Wait(5000)
            if LocalPlayer.state.Gang then
                -- Get nearby players in scopw
                local players = GetActivePlayers()

                for i = 1, #players, 1 do
                    if players[i] ~= U.Cache.PlayerId then
                        local ped = GetPlayerPed(players[i]) --Get players ped                    
                        local serverId = GetPlayerServerId(players[i]) --Get players server id
                        local playerState = Player(serverId).state --Get players state
                        if LocalPlayer.state.Gang.name == playerState.Gang?.name then
                            if not MemberBlips[serverId] then --If the player is in the same gang and doesn't have a blip
                                DevPrint('Adding Blip for', playerState.Character.NickName)
                                MemberBlips[serverId] = BlipAddForEntity(-1749618580, ped)
                                Citizen.InvokeNative(0x9CB1A1623062F402, MemberBlips[serverId], playerState.Character.NickName)
                            end
                        else
                            if MemberBlips[serverId] then --If the player is not in the same gang and has a blip
                                RemoveBlip(MemberBlips[serverId])
                                MemberBlips[serverId] = nil
                            end
                        end
                    end
                end

                -- Cleanup blips for players who are no longer in scope
                -- Im not sure this is needed (I know in FiveM it is)
                for serverId, blip in next, MemberBlips do
                    -- Check to see if an invalid player id is returned
                    local player = GetPlayerFromServerId(serverId)
                    if player == -1 then --If the player is not in scope and has a blip remove it
                        DevPrint('Removing Blip for', serverId)
                        RemoveBlip(blip)
                        MemberBlips[serverId] = nil
                    end
                end
            end
        end
    end)
end