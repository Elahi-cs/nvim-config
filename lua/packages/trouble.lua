return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
        { "<leader>tr", "<cmd>Trouble diagnostics toggle<cr>", desc = "Toggle Trouble diagnostics" },
    },
    opts = {
        auto_close = false, -- auto close when there are no items
        auto_open = false, -- auto open when there are items
        auto_preview = true, -- automatically open preview when on an item
        auto_jump = false, -- auto jump to the item when there's only one
        focus = false, -- don't focus the window when opened
        multiline = true, -- render multi-line messages
        indent_guides = true, -- show indent guides (was indent_lines in v2)
        -- results window: bottom split, 10 rows, single border
        -- (replaces v2 position/height/win_config)
        win = {
            type = "split",
            position = "bottom",
            size = 10,
            border = "single",
        },
        icons = {
            indent = {
                fold_open = " ", -- was fold_open in v2
                fold_closed = " ", -- was fold_closed in v2
            },
        },
    },
}
