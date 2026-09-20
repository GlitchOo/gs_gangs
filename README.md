# gs_gangs

A gang management system for RedM (VORP and RSG). Opens a ledger book UI for bosses to manage members and a shared treasury.

# Features

- Frameworks - VORP (`Config.Gangs`) or RSG (`rsg-core` Shared.Gangs / `SetGang`).
- Locales - Includes English but can be translated to any language.
- Cooldowns - Adjust the cooldown required for a player to wait after leaving one gang to join another.
- Keybind - Enable/Disable a keybind to open the gang menu instead of a command.
- Member blips - Enable/Disable member blips (Display blips of nearby gang members of the same gang).
- Commands - Change the various commands listed below and permissions.
- Distance checks - Adjust the distance to invite new members via the menu.
- Max Members - Adjust the maximum number of members allowed in a single gang.
- Shared ledger - Gang treasury in `gs_gang_ledgers` (separate from rsg-gangmenu society funds).
- Client/Server API.

![Preview 1](https://static.glitchd.app/redm/gangs/gang_menu_1.png?v2)
![Preview 2](https://static.glitchd.app/redm/gangs/gang_menu_2.png?v2)
![Preview 3](https://static.glitchd.app/redm/gangs/gang_menu_3.png?v2)
![Preview 4](https://static.glitchd.app/redm/gangs/gang_menu_4.png?v2)
![Preview 5](https://static.glitchd.app/redm/gangs/gang_menu_5.png?v2)
![Preview 5](https://static.glitchd.app/redm/gangs/gang_menu_6.png?v2)
![Preview 5](https://static.glitchd.app/redm/gangs/gang_menu_7.png?v2)

# Framework

Set in `config.lua`:

```lua
Framework = 'auto', -- 'vorp' | 'rsg' | 'auto'
```

## VORP

- Gang list and ranks live in `Config.Gangs`.
- Membership is stored on the VORP `characters.gang` column (auto-migrated).
- Staff access: VORP group (`Config.Commands.staff.group`) or ACE `gangs.set`.

## RSG (sit-in for rsg-gangmenu)

- Gang list and ranks come from `rsg-core/shared/gangs.lua` (`RSGCore.Shared.Gangs`).
- Boss grades (`isboss = true`) get menu + ledger deposit/withdraw permission.
- Membership uses `Player.Functions.SetGang` / the `players.gang` JSON (same as core).
- Blip colors: `Config.GangColors` (Shared.Gangs has no color field).
- Ledger money uses `gs_gang_ledgers` (fresh balances; not `management_funds`).
- Leave cooldown uses `gs_gang_cooldowns`.
- Staff access: ACE `gangs.set` or RSG `admin` / `god` permission.
- Stash / location prompts from rsg-gangmenu are not included.

**Stop ensuring `rsg-gangmenu`** when using this on RSG so you do not run two boss menus or two money systems.

Edit gangs in rsg-core, not in `Config.Gangs` (that table is replaced at runtime on RSG).

# Commands

/gangmenu - Opens the gang ledger book for members who have menu permission.
    - Invite members.
    - Manage members.
        - Kick members.
        - Change members' rank.
    - Deposit / withdraw ledger (if permitted).

/mygang - Display the player's gang and rank.

Staff (ACE / group as above):

/setgang [PlayerId] [GangName] [GangRank]

Example:
/setgang 1 DelLobo 2 - VORP: add to DelLobo rank 2.
/setgang 1 odriscoll 3 - RSG: add to odriscoll grade 3 (boss in default core).
/setgang 1 none 0 - Remove the player from their gang.

# Statebags

```
local GangName = Player(ServerID).state.Gang.name -- Gang key
local GangRank = Player(ServerID).state.Gang.rank -- Rank / grade level
```

# API

## Client

```
exports.gs_gangs:GetPlayerGang()
exports.gs_gangs:GetPlayerGangRank()
exports.gs_gangs:IsPlayerInGang()
exports.gs_gangs:HasPermission()
exports.gs_gangs:GetAllGangs()
exports.gs_gangs:GetGangByName(name|string)
exports.gs_gangs:OpenMenu()
exports.gs_gangs:AddMenuOption(element|table) -- legacy; book UI does not render these
```

## Server

```
exports.gs_gangs:GetPlayerGang(source|number)
exports.gs_gangs:GetPlayerGangRank(source|number)
exports.gs_gangs:IsPlayerInGang(source|number)
exports.gs_gangs:HasPermission(source|number)
exports.gs_gangs:GetAllGangs()
exports.gs_gangs:GetGangByName(name|string)
exports.gs_gangs:GetGangAccount(gangName)
exports.gs_gangs:AddGangMoney(gangName, amount)
exports.gs_gangs:RemoveGangMoney(gangName, amount)
```

# Dependencies

- [OxMySQL](https://github.com/overextended/oxmysql)
- VORP: [vorp_core](https://github.com/VORPCORE/vorp_core-lua) OR RSG: [rsg-core](https://github.com/Rexshack-RedM/rsg-core) (ox_lib recommended for notifies)
