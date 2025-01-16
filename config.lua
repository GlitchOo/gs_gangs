Config = {
    EnableDev = true,                                   -- Enable Dev Mode

    Cooldown = 60*60*24,                                -- Cooldown to recruit someone after they've left another gang (in seconds)(24 hours)

    KeyBind = {
        enable = true,                                  -- Enable Keybind
        openMenu = 0x064D1698,                          -- Keybind to open the menu (HOME)
    },

    ShowNearbyMembers = true,                           -- Show nearby gang members within scope

    Commands = {
        openMenu = 'gangmenu',                          -- Command to open the menu
        checkGang = 'mygang',                           -- Command to check a player's gang
        staff = {
            set = 'setgang',                            -- Command to set a player's gang
            get = 'getgang',                            -- Command to get a player's gang
            group = 'admin',                            -- Group to use the command
            acePerm = 'gangs.set',                      -- Ace Permission to use the command
        }
    },

    MaxInviteDistance = 10,                             -- Max distance to invite a player

    MaxMembers = 10,                                    -- Max members per gang

    -- Gangs
    Gangs = {
        ['DelLobo'] = {
            label = 'Del Lobo',                         -- Gang Name
            ranks = {
                [1] = {
                    label = 'Trail Scout',              -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [2] = {
                    label = 'Sharp',                    -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [3] = {
                    label = 'Rustler',                  -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [4] = {
                    label = 'Second',                   -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [5] = {
                    label = 'Bossman',                  -- Rank Name
                    permissionMenu = true               -- Permission to open the menu
                },
            },
        },

        ['Laramie'] = {
            label = 'Laramie',                         -- Gang Name
            ranks = {
                [1] = {
                    label = 'Trail Scout',              -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [2] = {
                    label = 'Sharp',                    -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [3] = {
                    label = 'Rustler',                  -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [4] = {
                    label = 'Second',                   -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [5] = {
                    label = 'Bossman',                  -- Rank Name
                    permissionMenu = true               -- Permission to open the menu
                },
            },
        },

        ['Murfree'] = {
            label = 'Murfree',                          -- Gang Name
            ranks = {
                [1] = {
                    label = 'Trail Scout',              -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [2] = {
                    label = 'Sharp',                    -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [3] = {
                    label = 'Rustler',                  -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [4] = {
                    label = 'Second',                   -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [5] = {
                    label = 'Bossman',                  -- Rank Name
                    permissionMenu = true               -- Permission to open the menu
                },
            },
        },

        ['Odriscoll'] = {
            label = 'Odriscoll',                       -- Gang Name
            ranks = {
                [1] = {
                    label = 'Trail',
                    permissionMenu = false              -- Permission to open the menu
                },
                [2] = {
                    label = 'Sharp',                    -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [3] = {
                    label = 'Rustler',                  -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [4] = {
                    label = 'Second',                   -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [5] = {
                    label = 'Bossman',                  -- Rank Name
                    permissionMenu = true               -- Permission to open the menu
                },
            },
        },

        ['Skinner'] = {
            label = 'Skinner',                          -- Gang Name
            ranks = {
                [1] = {
                    label = 'Trail Scout',              -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [2] = {
                    label = 'Sharp',                    -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [3] = {
                    label = 'Rustler',                  -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [4] = {
                    label = 'Second',                   -- Rank Name
                    permissionMenu = false              -- Permission to open the menu
                },
                [5] = {
                    label = 'Bossman',                  -- Rank Name
                    permissionMenu = true               -- Permission to open the menu
                },
            },
        },
    }
}