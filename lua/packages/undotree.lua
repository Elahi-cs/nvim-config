-- Undo history visualization. Keymap moved here from after/plugin/undotree.lua.
return {
    "mbbill/undotree",
    priority = 1000, -- Load early to ensure autoload functions are available
    lazy = false,
    keys = {
        { "<leader>u", vim.cmd.UndotreeToggle, desc = "Toggle undotree" },
    },
    config = function()
        -- Create our own safer autocommand that checks function availability
        vim.api.nvim_create_augroup("UndotreeSafe", { clear = true })
        vim.api.nvim_create_autocmd("BufReadPost", {
            group = "UndotreeSafe",
            callback = function()
                if vim.fn.exists("*undotree#UndotreePersistUndo") == 1 then
                    vim.fn["undotree#UndotreePersistUndo"](0)
                end
            end,
        })
        vim.cmd("autocmd! undotreeDetectPersistenceUndo")
    end,
}
