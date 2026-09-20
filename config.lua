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
    InvitePromptTimeout = 30,                           -- Seconds to accept/decline invite prompt

    MaxMembers = 10,                                    -- Max members per gang

    Ledger = {
        enable = true,                                  -- Shared gang treasury in the book UI
        currency = 0,                                   -- VORP currency (0 = cash, 1 = gold, 2 = rol)
        logLimit = 12,                                  -- Recent ledger entries shown under balance
        -- Ped anim while the book NUI is open
        -- 'notebook' = WORLD_HUMAN_WRITE_NOTEBOOK (recommended, standing write)
        -- false / 'none' = disabled
        anim = 'notebook',
    },

    -- Gangs
    Gangs = {
        ['DelLobo'] = {
            label = 'Del Lobo',                         -- Gang Name
            color = 'BLIP_MODIFIER_MP_COLOR_1',         -- Gang Color
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
                    permissionMenu = true,              -- Permission to open the menu
                    permissionLedgerDeposit = true,     -- Deposit into gang ledger
                    permissionLedgerWithdraw = true,    -- Withdraw from gang ledger
                },
            },
        },

        ['Laramie'] = {
            label = 'Laramie',                         -- Gang Name
            color = 'BLIP_MODIFIER_MP_COLOR_2',         -- Gang Color
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
                    permissionMenu = true,              -- Permission to open the menu
                    permissionLedgerDeposit = true,
                    permissionLedgerWithdraw = true,
                },
            },
        },

        ['Murfree'] = {
            label = 'Murfree',                          -- Gang Name
            color = 'BLIP_MODIFIER_MP_COLOR_3',         -- Gang Color
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
                    permissionMenu = true,              -- Permission to open the menu
                    permissionLedgerDeposit = true,
                    permissionLedgerWithdraw = true,
                },
            },
        },

        ['Odriscoll'] = {
            label = 'Odriscoll',                       -- Gang Name
            color = 'BLIP_MODIFIER_MP_COLOR_4',        -- Gang Color
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
                    permissionMenu = true,              -- Permission to open the menu
                    permissionLedgerDeposit = true,
                    permissionLedgerWithdraw = true,
                },
            },
        },

        ['Skinner'] = {
            label = 'Skinner',                          -- Gang Name
            color = 'BLIP_MODIFIER_MP_COLOR_5',         -- Gang Color
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
                    permissionMenu = true,              -- Permission to open the menu
                    permissionLedgerDeposit = true,
                    permissionLedgerWithdraw = true,
                },
            },
        },
    }
}