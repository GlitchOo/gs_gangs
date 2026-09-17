local Menu = exports.vorp_menu:GetMenuData()
local ExternalMenus = {}

--- Add Item To Menu
--- @param resource string
--- @param item table
function AddItemToMenu(resource, item)
    ExternalMenus[resource] = ExternalMenus[resource] or {}
    table.insert(ExternalMenus[resource], item)
end

--- Change Rank Menu
--- @param members table
--- @param member table
function ChangeRank(members, member)
    DevPrint('ChangeRank', json.encode(member))
    Menu.CloseAll()

    local MenuElements = {}

    for i=1, #Config.Gangs[member.gang.name].ranks, 1 do
        table.insert(MenuElements, {
            label = Config.Gangs[member.gang.name].ranks[i].label, 
            value = i,
            desc = _('change_rank_desc', Config.Gangs[member.gang.name].ranks[i].label)
        })
    end

    Menu.Open("default", U.Cache.Resource, "change_rank",
    {
        title = _('member_title', member.firstname, member.lastname),
        subtext = _('change_rank_subtext'),
        align = "top",
        elements = MenuElements,
        lastmenu = "ViewMember",
        itemHeight = "2vh",
    },

    function(data, menu)
        if (data.current == "backup") then
            return _G[data.trigger](members, member)
        end

        TriggerServerEvent('gs_gangs:server:changeRank', member.charidentifier, data.current.value)
        member.gang.rank = data.current.value
        ViewMember(members, member)
    end, function(data, menu)
        menu.close() 
    end)
end

--- Member Menu
--- @param members table
--- @param member table
function ViewMember(members, member)
    DevPrint('ViewMember', json.encode(member))
    Menu.CloseAll()

    local MenuElements = {
        {
            label = _('change_rank'),
            value = 'member_ranks',
            desc = _('member_ranks_desc')
        },
        {
            label = _('kick_member'),
            value = 'kick_member',
            desc = _('kick_member_desc'),
        },
    }

    Menu.Open("default", U.Cache.Resource, "member",
    {
        title = _('member_title', member.firstname, member.lastname),
        subtext = _('member_subtext', Config.Gangs[member.gang.name].ranks[member.gang.rank]?.label or 'Unknown Rank'),
        align = "top",
        elements = MenuElements,
        lastmenu = "MembersMenu",
        itemHeight = "2vh",
    },

    function(data, menu)
        if (data.current == "backup") then
            return _G[data.trigger](members)
        end

        if data.current.value == 'member_ranks' then
            ChangeRank(members, member)
        elseif data.current.value == 'kick_member' then
            menu.displayInput({
                inputType = 'yesno',
                header = _('kick_member'),
                description = _('kick_confirm'),
                buttons = { confirm = _('confirm'), cancel = _('cancel') },
            }, function(confirmed)
                if confirmed then
                    TriggerServerEvent('gs_gangs:server:kickMember', member.charidentifier)
                end
            end)
        end
    end, function(data, menu)
        menu.close()
    end)
end

--- Members Menu
--- @param members table
function MembersMenu(members)
    DevPrint('MembersMenu', json.encode(members))
    Menu.CloseAll()

    local MenuElements = {}

    for i=1, #members, 1 do
        local rankLabel = Config.Gangs[members[i].gang.name].ranks[members[i].gang.rank]?.label or 'Unknown Rank'
        table.insert(MenuElements, {
            label = members[i].firstname .. ' ' .. members[i].lastname, 
            value = members[i],
            desc = _('member_desc', members[i].firstname, members[i].lastname, rankLabel)
        })
    end

    Menu.Open("default", U.Cache.Resource, "members",

    {
        title = _('members'),
        subtext = _('members_subtext', #members, Config.MaxMembers),
        align = "top",
        elements = MenuElements,
        lastmenu = "OpenMenu",
        itemHeight = "2vh",
    },

    function(data, menu)
        if (data.current == "backup") then
            return _G[data.trigger]()
        end
        
        ViewMember(members, data.current.value)
    end, function(data, menu)
        menu.close()
    end)
end

---Builds a label for a nearby player from their character statebag.
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

--- Invite menu listing nearby players within MaxInviteDistance
function InviteMenu()
    DevPrint('InviteMenu')
    Menu.CloseAll()

    local myCoords = GetEntityCoords(PlayerPedId())
    local maxDist = Config.MaxInviteDistance
    local MenuElements = {}
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
                    local name = NearbyPlayerLabel(serverId)
                    table.insert(MenuElements, {
                        label = name,
                        value = serverId,
                        desc = gang and _('invite_already_in_gang', name) or _('invite_player_desc', name, math.floor(dist + 0.5)),
                        isDisabled = gang ~= nil,
                    })
                end
            end
        end
    end

    if #MenuElements == 0 then
        table.insert(MenuElements, {
            label = _('invite_none_nearby'),
            value = false,
            desc = _('invite_none_nearby_desc', maxDist),
            isNotSelectable = true,
        })
    end

    Menu.Open("default", U.Cache.Resource, "invite",
    {
        title = _('invite'),
        subtext = _('invite_nearby_subtext', maxDist),
        align = "top",
        elements = MenuElements,
        lastmenu = "OpenMenu",
        itemHeight = "2vh",
    },

    function(data, menu)
        if (data.current == "backup") then
            return _G[data.trigger]()
        end

        if data.current.value then
            TriggerServerEvent('gs_gangs:server:recruit', data.current.value)
            menu.close()
        end
    end, function(data, menu)
        menu.close()
    end)
end

--- Gangs Menu
function OpenMenu()
    DevPrint('OpenMenu')

    if not LocalPlayer.state.Gang then
        return
    end

    if not Config.Gangs[LocalPlayer.state.Gang.name].ranks[LocalPlayer.state.Gang.rank].permissionMenu then
        return
    end

    Menu.CloseAll()

    local MenuElements = {
        {
            label = _('members'),
            value = 'members',
            desc = _('members_desc')
        },
        {
            label = _('invite'),
            value = 'invite',
            desc = _('invite_desc')
        }
    }

    for k, v in pairs(ExternalMenus) do
        for i=1, #v, 1 do
            table.insert(MenuElements, v[i])
        end
    end

    Menu.Open("default", U.Cache.Resource, "gangs",

    {
        title = Config.Gangs[LocalPlayer.state.Gang.name].label,
        align = "top",
        elements = MenuElements,
        itemHeight = "2vh",
    },

    function(data, menu)
        if data.current.value == 'members' then
            TriggerServerEvent('gs_gangs:server:getMembers')
        elseif data.current.value == 'invite' then
            InviteMenu()
        end

        if data.current.event then
            if data.current.isServer then
                TriggerServerEvent(data.current.event, data.current)
            else
                TriggerEvent(data.current.event, data.current)
            end
        elseif data.current.action then
            _G[data.action](data.current)
        end

        if data.current.closeMenu then
            menu.close()
        end

    end, function(data, menu)
        menu.close()
    end)
end

--- Event triggered when the player receives an invitation to join a gang
--- @param gangName string
--- @param player number
RegisterNetEvent('gs_gangs:client:recruit', function(gangName, player)
    DevPrint('gs_gangs:client:recruit', gangName, player)

    Menu.CloseAll()

    local MenuElements = {
        { 
            label = _('accept'), 
            value = true,
            desc = _('accept_desc', Config.Gangs[gangName].label)
        },
        { 
            label = _('decline'), 
            value = false,
            desc = _('decline_desc', Config.Gangs[gangName].label)
        },
    }

    Menu.Open("default", U.Cache.Resource, "recruit",

    {
        title = _('invite_title', Config.Gangs[gangName].label),
        subtext = _('invite_subtext', Config.Gangs[gangName].label),
        align = "top",
        elements = MenuElements,
        itemHeight = "2vh",
    },


    function(data, menu)

        TriggerServerEvent('gs_gangs:server:recruitResponse', data.current.value, player)
        return menu.close()

    end, function(data, menu)
        TriggerServerEvent('gs_gangs:server:recruitResponse', false, player)
        menu.close()
    end)
end)

--- Event triggered to display the gangs members
--- @param members table
RegisterNetEvent('gs_gangs:client:members', function(members)
    for i=1, #members, 1 do
        members[i].gang = json.decode(members[i].gang)
    end

    MembersMenu(members)
end)

--- Event triggered on resource stop
--- This will remove any added menu options (via api) from the menu
--- @param resource string
AddEventHandler('onResourceStop', function(resource)
    ExternalMenus[resource] = nil
end)

--- Opens the gane menu
--- @usage exports.gs_gangs:OpenMenu()
exports('OpenMenu', OpenMenu)