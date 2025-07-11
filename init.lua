require("settings")

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

-- Auto-install lazy.nvim if not present
if not vim.loop.fs_stat(lazypath) then
  print('Installing lazy.nvim....')
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
  print('Done.')
end


vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = "packages",
})

-- Set colorscheme
vim.opt.termguicolors = true

-- lua/packages/lsp.lua
-- 1) Shared “root markers” and capabilities for *all* servers
vim.lsp.config('*', {
  root_markers  = {'.git', 'go.mod', 'pyproject.toml'},
  capabilities  = vim.lsp.protocol.make_client_capabilities(),
})

-- 2) on_attach via the LspAttach autocommand
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(args)
    local bufnr = args.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc and 'LSP: '..desc })
    end

    -- Common mappings
    map('n', 'gd', vim.lsp.buf.definition,     'Go to Definition')
    map('n', 'gD', vim.lsp.buf.declaration,    'Go to Declaration')
    map('n', 'gi', vim.lsp.buf.implementation, 'Go to Implementation')
    map('n', 'K',  vim.lsp.buf.hover,          'Hover Docs')
    map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename Symbol')
    map('n', 'gr', vim.lsp.buf.references,     'References')
  end,
})

-- 3) Define each server’s config
vim.lsp.config('ruff', {
  cmd       = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
})

vim.lsp.config('gopls', {
  cmd       = { 'gopls' },
  filetypes = { 'go' },
  settings  = {
    gopls = {
      analyses    = { unusedparams = true },
      staticcheck = true,
    },
  },
})

-- 4) Enable them (auto-starts on matching filetypes & root markers)
vim.lsp.enable({ 'ruff', 'gopls' })
