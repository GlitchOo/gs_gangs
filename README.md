# gs_gangs

A simple gang management system for VORP/RedM
Gang status is stored in the database, the column is automatically added to vorps existing characters table

# Features

- Locales - Includes english but can be translated to any language
- Cooldowns - Adjust the cooldown required for a player to wait after leaving one gang to join another.
- Keybind - Enable/Disable a keybind to open the gang menu instead of a command.
- Member blips - Enable/Disable member blips (Display blips of nearby gang members of same gang).
- Commands - Change the various commands listed below and permissions
- Distance checks - Adjust the distance to invite new members via menu
- Max Members - Adjust the amount/maximum members aloowed in a single gang
- Gangs - Easily configure gangs, ranks, etc.
- Client/Server API


[Example Video](https://youtu.be/UEe1d2MUIU8)

![Preview 1](https://i.gyazo.com/4c719841464957d8b5614891379b120a.png)
![Preview 2](https://i.gyazo.com/90e974b5051257e20f7c88af8368acab.png)
![Preview 3](https://i.gyazo.com/6eab8946aedae5ab0a69441e70bfb418.png)
![Preview 4](https://i.gyazo.com/7501c1acab065728f31eee9cc831ac69.png)


# Commands

/gangmenu - Opens the gang menu for members who have menu permission
    - Invite members
    - Manage members
        - Kick members
        - Change members rank

/mygang - Display the players gang and rank

The following command is for permitted access (Changed in the config [AcePerms | Group])
/setgang [PlayerId] [GangName] [GangRank]

Example:
/setgang 1 DelLobo 2 - This will add a player to DelLobo with rank 2
/setgang 1 none 0 - This will remove a player from the gang they're a member of if any

# Statebags

The gang system uses FiveM/RedM's statebag system.
These can be accessed both server side and client side for use in other resources
```
local GangName = Player(ServerID).state.Gang.name -- The key index name of the gang the player is in
local GangRank = Player(ServerID).state.Gang.rank -- The rank number the of the gang the player is in
```

# API

## Client

```
-- Returns a table of the gang player is in or false if none
exports.gs_gangs:GetPlayerGang()

-- Returns a table of the players rank the player is or false if not in a gang
exports.gs_gangs:GetPlayerGangRank()

-- Returns true|false if the player is a member of any gang
exports.gs_gangs:IsPlayerInGang()

-- Returns true|false if the player has menu access
exports.gs_gangs:HasPermission()

-- Returns a table of all configured gangs
exports.gs_gangs:GetAllGangs()

-- Returns a table of a the gang specified
exports.gs_gangs:GetGangByName(name|string)
```

## Server

```
-- Returns a table of the gang player is in or false if none
exports.gs_gangs:GetPlayerGang(source|number)

-- Returns a table of the players rank the player is or false if not in a gang
exports.gs_gangs:GetPlayerGangRank(source|number)

-- Returns true|false if the player is a member of any gang
exports.gs_gangs:IsPlayerInGang(source|number)

-- Returns true|false if the player has menu access
exports.gs_gangs:HasPermission(source|number)

-- Returns a table of all configured gangs
exports.gs_gangs:GetAllGangs()

-- Returns a table of a the gang specified
exports.gs_gangs:GetGangByName(name|string)
```

# Dependencies
While this resource was built around VORP it could be modified for any framework.

[Vorp Core](https://github.com/VORPCORE/vorp_core-lua)

[Vorp Menu](https://github.com/VORPCORE/vorp_menu)

[Vorp Inputs](https://github.com/VORPCORE/vorp_inputs-lua)