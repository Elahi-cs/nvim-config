-- LSP setup for Neovim 0.11+ built-in client.
-- nvim-lspconfig ships the per-server defaults (cmd, filetypes, root_dir) via
-- its lsp/*.lua files; here we only override capabilities + settings, wire
-- keymaps on attach, and enable the servers.

-- Shared capabilities: base client caps + nvim-cmp's completion caps.
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok then
    capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
end

vim.lsp.config("*", {
    root_markers = { ".git", "go.mod", "pyproject.toml" },
    capabilities = capabilities,
})

-- Python: pyright owns hover/definitions/types.
vim.lsp.config("pyright", {
    settings = {
        python = {
            analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
            },
        },
    },
})

-- Python: ruff owns lint + format. It needs no settings overrides (nvim-lspconfig
-- supplies the defaults) and is enabled below; its hover is disabled on attach.

-- Go: existing gopls config retained.
vim.lsp.config("gopls", {
    settings = {
        gopls = {
            analyses = { unusedparams = true },
            staticcheck = true,
        },
    },
})

-- Keymaps + ruff/pyright hover split, applied when any server attaches.
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        -- Let pyright own hover; ruff focuses on lint/format.
        if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
        end

        local bufnr = args.buf
        local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc and "LSP: " .. desc })
        end
        map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
        map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
        map("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
        map("n", "gr", vim.lsp.buf.references, "References")
        map("n", "K", vim.lsp.buf.hover, "Hover Docs")
        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
    end,
})

vim.lsp.enable({ "pyright", "ruff", "gopls" })
