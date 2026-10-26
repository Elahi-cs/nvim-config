-- Fuzzy finder. Keymaps moved here from after/plugin/telescope.lua.
return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    config = function()
        -- Preview treesitter highlighting is disabled: this telescope release predates
        -- nvim-treesitter's `main`-branch rewrite and calls the now-removed
        -- `nvim-treesitter.parsers.ft_to_lang`, crashing the previewer. Falls back to
        -- Vim's regex syntax highlighting in the preview pane instead.
        require("telescope").setup({
            defaults = {
                preview = { treesitter = false },
            },
        })

        local builtin = require("telescope.builtin")
        vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "Telescope: find files" })
        vim.keymap.set("n", "<leader>pg", builtin.git_files, { desc = "Telescope: git files" })
        vim.keymap.set("n", "<leader>ps", function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end, { desc = "Telescope: grep" })
        vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "Telescope: LSP references" })
    end,
}
