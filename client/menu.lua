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
            confirm = {
                type = "enableinput",
                inputType = "input",
                button = _('confirm'),
                placeholder = "",
                style = "block",
                attributes = {
                    type = "text",
                    inputHeader  = _('kick_confirm', _('kick')),
                    pattern = ".*",
                    style = "border-radius: 10px; background-color: ; border:none;"
                }
            }
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
            local result = exports.vorp_inputs:advancedInput(data.current.confirm)
            if result == _('kick') then
                TriggerServerEvent('gs_gangs:server:kickMember', member.charidentifier)
            end
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
            local input = {
                type = "enableinput",
                inputType = "input",
                placeholder = "0",
                button = _('confirm'),
                style = "block",
                attributes = {
                    type = "number",
                    inputHeader = _('invite_input'),
                    pattern = "[0-9]",
                    style = "border-radius: 10px; background-color: ; border:none;"
                }
            }

            local result = exports.vorp_inputs:advancedInput(input)
            local target = tonumber(result)
            if target then
                TriggerServerEvent('gs_gangs:server:recruit', target)
            end
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