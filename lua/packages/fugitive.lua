-- Git integration. Keymap moved here from after/plugin/fugitive.lua.
return {
    "tpope/vim-fugitive",
    lazy = false,
    config = function()
        vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git status" })
    end,
}
