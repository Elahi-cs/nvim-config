# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a personal Neovim configuration using lazy.nvim as the package manager. The configuration follows a modular structure:

- `init.lua` - Entry point that bootstraps lazy.nvim, loads settings, and requires `config.lsp`
- `lua/settings/` - Core Neovim settings and key remaps
  - `global.lua` - Global options (leader key, indentation, line numbers, persistent undo, etc.)
  - `remap.lua` - Custom key mappings (leader is `<Space>`)
- `lua/config/lsp.lua` - Built-in LSP setup (capabilities, per-server settings, LspAttach keymaps)
- `lua/packages/` - Plugin specifications for lazy.nvim; each file returns a plugin table with its config inline
- `scripts/healthcheck.sh` - Headless verification checks for a fresh install
- `lazy-lock.json` - Lock file for plugin versions

## Key Architecture Details

### Package Management
- Uses lazy.nvim with plugin specs in `lua/packages/` directory
- Each package file returns a plugin table that lazy.nvim processes
- Each plugin's configuration (setup, keymaps) lives inline in its spec via `config`/`keys`/`opts` (there is no `after/plugin/` directory)

### LSP Configuration
- Neovim 0.11+ built-in LSP, configured in `lua/config/lsp.lua` (not inline in init.lua)
- `nvim-lspconfig` supplies per-server defaults (cmd/filetypes/root_dir); `lua/config/lsp.lua` overrides capabilities + settings and calls `vim.lsp.enable()`
- Server binaries (pyright, ruff, debugpy) are installed via Mason (`lua/packages/mason.lua`)
- Python: pyright provides definitions/hover/types; ruff provides lint/format (its hover is disabled)
- Shared root markers: `.git`, `go.mod`, `pyproject.toml`
- Enabled servers: pyright, ruff, gopls

### Key Leader Mappings
- Leader key: `<Space>`
- `<leader>pv` - File explorer (netrw)
- `<leader>pf` - Telescope file finder
- `<leader>pg` - Telescope git files
- `<leader>ps` - Telescope grep
- `<leader>gcf` - Navigate to config folder
- `<leader>rdm` - Open README
- `<leader>map` - Open remaps file
- `<leader>d...` - Debugging (see README for the full DAP keymap table)

## Installation and Development

### Installation
- Linux: Clone repo to `~/.config/nvim/`
- Windows: Place `nvim` folder in `C:/Users/[user]/AppData/Local/nvim`
- `install.sh` script clones to `$HOME/.test_config` for testing
- On first launch, Mason installs pyright/ruff/debugpy automatically

### Plugin Management
- Add new plugins by creating files in `lua/packages/` that return plugin specs
- Put each plugin's setup/keymaps inline in its spec (`config`/`keys`/`opts`)
- Run `:Lazy` to manage plugins (install, update, clean); `:Mason` to manage tool binaries

### Verification
- Run `./scripts/healthcheck.sh` to verify a fresh install headlessly
- No build system or unit-test suite; changes are applied by restarting Neovim or `:source`

## Major Plugins
- telescope.nvim - Fuzzy finder
- harpoon - Quick buffer navigation
- undotree - Undo history visualization
- vim-fugitive - Git integration
- nvim-treesitter - Syntax highlighting
- trouble.nvim - Diagnostics viewer
- refactoring.nvim - Code refactoring tools (currently disabled)
- mason.nvim + mason-tool-installer - external tool (LSP/DAP) installer
- nvim-cmp - Autocompletion (config in lua/packages/completion.lua)
- nvim-dap + nvim-dap-ui + nvim-dap-python - Python debugging
- markdown-preview.nvim - Markdown preview in browser
