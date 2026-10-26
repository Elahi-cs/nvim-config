-- Syntax highlighting / parsing. Setup moved here from after/plugin/treesitter.lua.
-- Uses the nvim-treesitter `main` branch API (the old `nvim-treesitter.configs`
-- module is gone). Parsers are compiled with the `tree-sitter` CLI, which must
-- be on PATH; highlighting is started per buffer via Neovim's built-in API.
return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local ts = require("nvim-treesitter")
        ts.install({ "javascript", "json", "lua", "vim", "python", "c", "vimdoc", "query" })

        -- Start highlighting on every filetype with a parser, installing missing
        -- parsers on first use (replaces the old `auto_install` option).
        local available = nil
        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("UserTreesitter", {}),
            callback = function(args)
                local lang = vim.treesitter.language.get_lang(args.match)
                if not lang then
                    return
                end
                if pcall(vim.treesitter.start, args.buf, lang) then
                    return
                end
                available = available or ts.get_available()
                if vim.tbl_contains(available, lang) then
                    ts.install(lang):await(function()
                        if vim.api.nvim_buf_is_valid(args.buf) then
                            pcall(vim.treesitter.start, args.buf, lang)
                        end
                    end)
                end
            end,
        })
    end,
}
