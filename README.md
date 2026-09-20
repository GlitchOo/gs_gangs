# gs_gangs

A simple gang management system for VORP/RedM. Gang status is stored in the database, and the column is automatically added to VORP's existing characters table.

# Features

- Locales - Includes English but can be translated to any language.
- Cooldowns - Adjust the cooldown required for a player to wait after leaving one gang to join another.
- Keybind - Enable/Disable a keybind to open the gang menu instead of a command.
- Member blips - Enable/Disable member blips (Display blips of nearby gang members of the same gang).
- Commands - Change the various commands listed below and permissions.
- Distance checks - Adjust the distance to invite new members via the menu.
- Max Members - Adjust the maximum number of members allowed in a single gang.
- Gangs - Easily configure gangs, ranks, etc.
- Client/Server API.

![Preview 1](https://static.glitchd.app/redm/gangs/gang_menu_1.png?v2)
![Preview 2](https://static.glitchd.app/redm/gangs/gang_menu_2.png?v2)
![Preview 3](https://static.glitchd.app/redm/gangs/gang_menu_3.png?v2)
![Preview 4](https://static.glitchd.app/redm/gangs/gang_menu_4.png?v2)
![Preview 5](https://static.glitchd.app/redm/gangs/gang_menu_5.png?v2)
![Preview 5](https://static.glitchd.app/redm/gangs/gang_menu_6.png?v2)
![Preview 5](https://static.glitchd.app/redm/gangs/gang_menu_7.png?v2)

# Commands

/gangmenu - Opens the gang ledger book for members who have menu permission.
    - Invite members.
    - Manage members.
        - Kick members.
        - Change members' rank.

/mygang - Display the player's gang and rank.

The following command is for permitted access (Changed in the config [AcePerms | Group]):

/setgang [PlayerId] [GangName] [GangRank]

Example:
/setgang 1 DelLobo 2 - This will add a player to DelLobo with rank 2.
/setgang 1 none 0 - This will remove a player from the gang they're a member of, if any.

# Statebags

The gang system uses FiveM/RedM's statebag system. These can be accessed both server-side and client-side for use in other resources.
```
local GangName = Player(ServerID).state.Gang.name -- The key index name of the gang the player is in.
local GangRank = Player(ServerID).state.Gang.rank -- The rank number of the gang the player is in.
```

# API

## Client

```
-- Returns a table of the gang the player is in or false if none.
exports.gs_gangs:GetPlayerGang()

-- Returns a table of the player's rank or false if not in a gang.
exports.gs_gangs:GetPlayerGangRank()

-- Returns true|false if the player is a member of any gang.
exports.gs_gangs:IsPlayerInGang()

-- Returns true|false if the player has menu access.
exports.gs_gangs:HasPermission()

-- Returns a table of all configured gangs.
exports.gs_gangs:GetAllGangs()

-- Returns a table of the specified gang.
exports.gs_gangs:GetGangByName(name|string)

-- Add menu element to gang menu (displayed when gang mneu is opened)
exports.gs_gangs:AddMenuOption(element|table)

Ex:
exports.gs_gangs:AddMenuOption({
    { 
        label = "name",             -- Menu element label
        value = "value",            -- Menu element value
        desc = "description",       -- Menu description
        isServer = false,           -- Is event for server? (Only used for event)
        event = "someevent",        -- Event to be triggered on element trigger
        action = "somefunction",    -- Function to be triggered on element trigger (Ignored if event is defined)
        closeMenu = true            -- Close menu on element trigger
    }
})
```

## Server

```
-- Returns a table of the gang the player is in or false if none.
exports.gs_gangs:GetPlayerGang(source|number)

-- Returns a table of the player's rank or false if not in a gang.
exports.gs_gangs:GetPlayerGangRank(source|number)

-- Returns true|false if the player is a member of any gang.
exports.gs_gangs:IsPlayerInGang(source|number)

-- Returns true|false if the player has menu access.
exports.gs_gangs:HasPermission(source|number)

-- Returns a table of all configured gangs.
exports.gs_gangs:GetAllGangs()

-- Returns a table of the specified gang.
exports.gs_gangs:GetGangByName(name|string)
```

# Dependencies

While this resource was built around VORP, it could be modified for any framework.

[Vorp Core](https://github.com/VORPCORE/vorp_core-lua)

[OxMySQL](https://github.com/overextended/oxmysql)
