return {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd([[colorscheme catppuccin]])
        vim.cmd([[highlight Normal guibg=none]])
        vim.cmd([[highlight NonText guibg=none]])
        -- catppuccin leaves netrwMarkFile resolving to Normal, making netrw
        -- marks (mf/mt) invisible. Give them a distinct bold accent instead.
        vim.cmd([[highlight netrwMarkFile guifg=#f9e2af gui=bold]])
    end,
}
