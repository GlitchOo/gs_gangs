local GangAPI = {}

--- Get the player's gang
--- @param source number
--- @return table | boolean
--- @usage GangAPI.GetPlayerGang(source)
--- @usage exports.gs_gangs:GetPlayerGang(source)
function GangAPI.GetPlayerGang(source)
    local gang = Player(source).state.Gang?.name
    if gang then
        return Config.Gangs[gang]
    end
    return false
end

--- Get the player's gang rank
--- @param source number
--- @return table | boolean
--- @usage GangAPI.GetPlayerGangRank(source)
--- @usage exports.gs_gangs:GetPlayerGangRank(source)
function GangAPI.GetPlayerGangRank(source)
    local pState = Player(source).state
    local gang = pState.Gang?.name or false
    local rank = pState.Gang?.rank or 0

    if gang then
        return Config.Gangs[gang].ranks[rank]
    end

    return false
end

--- Check if the player is in a gang
--- @param source number
--- @return boolean
--- @usage GangAPI.IsPlayerInGang(source)
--- @usage exports.gs_gangs:IsPlayerInGang(source)
function GangAPI.IsPlayerInGang(source)
    return Player(source).state.Gang and true or false
end

--- Check if the player has "boss" permission
--- @param source number
--- @return boolean
--- @usage GangAPI.HasPermission(source)
--- @usage exports.gs_gangs:HasPermission(source)
function GangAPI.HasPermission(source)
    local pState = Player(source).state
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

--- Get Gang by Name
--- @param name string
--- @return table | boolean
--- @usage GangAPI.GetGangByName(name)
--- @usage exports.gs_gangs:GetGangByName(name)
function GangAPI.GetGangByName(name)
    return Config.Gangs[name] or false
end

--- Export GangAPI
--- @return table
exports('GangAPI', function()
    return GangAPI
end)

--- Export GangAPI Functions
exports('GetPlayerGang', GangAPI.GetPlayerGang)
exports('GetPlayerGangRank', GangAPI.GetPlayerGangRank)
exports('IsPlayerInGang', GangAPI.IsPlayerInGang)
exports('HasPermission', GangAPI.HasPermission)
exports('GetAllGangs', GangAPI.GetAllGangs)
exports('GetGangByName', GangAPI.GetGangByName)