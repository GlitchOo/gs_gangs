local GangAPI = {}

--- Get the player's gang
--- @return table | boolean
--- @usage GangAPI.GetPlayerGang()
--- @usage exports.gs_gangs:GetPlayerGang()
function GangAPI.GetPlayerGang()
    local gang = LocalPlayer.state.Gang?.name
    if gang then
        return {
            name = gang,
            color = Config.Gangs[gang].color,
            label = Config.Gangs[gang].label,
            ranks = Config.Gangs[gang].ranks
        }
    end
    return false
end

--- Get the player's gang rank
--- @return table | boolean
--- @usage GangAPI.GetPlayerGangRank()
--- @usage exports.gs_gangs:GetPlayerGangRank()
function GangAPI.GetPlayerGangRank()
    local pState = LocalPlayer.state
    local gang = pState.Gang?.name or false
    local rank = pState.Gang?.rank or 0

    if gang then
        return Config.Gangs[gang].ranks[rank]
    end

    return false
end

--- Check if the player is in a gang
--- @return boolean
--- @usage GangAPI.IsPlayerInGang()
--- @usage exports.gs_gangs:IsPlayerInGang()
function GangAPI.IsPlayerInGang()
    return LocalPlayer.state.Gang and true or false
end

--- Check if the player has "boss" permission
--- @return boolean
--- @usage GangAPI.HasPermission()
--- @usage exports.gs_gangs:HasPermission()
function GangAPI.HasPermission()
    local pState = LocalPlayer.state
    local gang = pState.Gang?.name or false
    local rank = pState.Gang?.rank or 0

    if gang then
        return Config.Gangs[gang].ranks[rank].permissionMenu
    end

    return false
end

--- Get All Gangs
--- @return table
--- @usage GangAPI.GetAllGangs()
--- @usage exports.gs_gangs:GetAllGangs()
function GangAPI.GetAllGangs()
    return Config.Gangs
end

--- Get gang by name
--- @param name string
--- @return table
--- @usage GangAPI.GetGangByName('name')
--- @usage exports.gs_gangs:GetGangByName('name')
function GangAPI.GetGangByName(name)
    return Config.Gangs[name]
end

--- Add a menu option to the gang menu
--- @param item table
--- @usage GangAPI.AddMenuOption(item)
--- @usage exports.gs_gangs:AddMenuOption(item)
function GangAPI.AddMenuOption(item)
    local resource = GetInvokingResource()
    AddItemToMenu(resource, item)
end

--- GangAPI
exports('GangAPI', function()
    return GangAPI
end)

--- GangAPI exports
exports('GetPlayerGang', GangAPI.GetPlayerGang)
exports('GetPlayerGangRank', GangAPI.GetPlayerGangRank)
exports('IsPlayerInGang', GangAPI.IsPlayerInGang)
exports('HasPermission', GangAPI.HasPermission)
exports('AddMenuOption', GangAPI.AddMenuOption)
exports('GetAllGangs', GangAPI.GetAllGangs)
exports('GetGangByName', GangAPI.GetGangByName)
exports('OpenMenu', OpenMenu)