return {
    "nvim-neorg/neorg",
    build = ":Neorg sync-parsers",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        require("neorg").setup {
            load = {
                ["core.defaults"] = {}, -- Loads default behaviour
                ["core.concealer"] = {
                    config = {
                        -- Icons need changing because of Windows Terminal not rendering them
                        icons = {
                            todo = {
                                cancelled = {
                                    icon = "🗑️"
                                },
                                done = {
                                    icon = "✓"
                                },
                                on_hold = {
                                    icon = "⏸️"
                                },
                                pending = {
                                    icon = "⌚"
                                },
                                recurring = {
                                    icon = "🔁"
                                },
                                uncertain = {
                                    icon = "?"
                                },
                                undone = {
                                    icon = " "
                                },
                                urgent = {
                                    icon = "!"
                                },
                            }
                        }
                    }

                }, -- Adds pretty icons to your documents
                ["core.dirman"] = { -- Manages Neorg workspaces
                config = {
                    workspaces = {
                        notes = "~/notes",
                    },
                },
            },
        },
    }
end,
}
