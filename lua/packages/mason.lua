-- Installs and manages external tool binaries (LSP servers, debug adapters).
-- Loaded eagerly so Mason's bin dir is on PATH before any LSP client starts.
return {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    lazy = false,
    priority = 100,
    config = function()
        require("mason").setup()
        require("mason-tool-installer").setup({
            ensure_installed = {
                "pyright",  -- Python type-checking / definitions / hover
                "ruff",     -- Python lint + format
                "debugpy",  -- Python debug adapter
            },
            run_on_start = true,
        })
    end,
}
