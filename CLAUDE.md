# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a personal Neovim configuration using lazy.nvim as the package manager. The configuration follows a modular structure:

- `init.lua` - Entry point that loads settings and initializes lazy.nvim, includes built-in LSP configs for Python (ruff/pyright) and Go (gopls)
- `lua/settings/` - Core Neovim settings and key remaps
  - `global.lua` - Global options (leader key, indentation, line numbers, etc.)
  - `remap.lua` - Custom key mappings (leader is `<Space>`)
- `lua/packages/` - Plugin specifications for lazy.nvim (each file returns a plugin table)
- `after/plugin/` - Plugin configurations that run after plugins are loaded
- `lazy-lock.json` - Lock file for plugin versions

## Key Architecture Details

### Package Management
- Uses lazy.nvim with plugin specs in `lua/packages/` directory
- Each package file returns a plugin table that lazy.nvim processes
- Plugin configurations are split between package specs and `after/plugin/` files

### LSP Configuration
- Uses Neovim 0.11+ built-in LSP configuration (not nvim-lspconfig for basic servers)
- LSP servers are configured directly in `init.lua` using `vim.lsp.config()`
- Shared root markers: `.git`, `go.mod`, `pyproject.toml`
- Common LSP keymaps are set via `LspAttach` autocommand
- Enabled servers: ruff, gopls, pyright

### Key Leader Mappings
- Leader key: `<Space>`
- `<leader>pv` - File explorer (netrw)
- `<leader>pf` - Telescope file finder  
- `<leader>ps` - Telescope project search
- `<leader>gcf` - Navigate to config folder
- `<leader>rdm` - Open README
- `<leader>map` - Open remaps file

## Installation and Development

### Installation
- Linux: Clone repo to `~/.config/nvim/`
- Windows: Place `nvim` folder in `C:/Users/[user]/AppData/Local/nvim`
- `install.sh` script clones to `$HOME/.test_config` for testing

### Plugin Management
- Add new plugins by creating files in `lua/packages/` that return plugin specs
- Configure plugins in `after/plugin/` directory
- Run `:Lazy` to manage plugins (install, update, clean)

### No Build/Test Commands
This is a configuration repository with no build system, test suite, or linting commands. Changes are applied by restarting Neovim or using `:source` command.

## Major Plugins
- telescope.nvim - Fuzzy finder
- harpoon - Quick buffer navigation  
- undotree - Undo history visualization
- vim-fugitive - Git integration
- nvim-treesitter - Syntax highlighting
- trouble.nvim - Diagnostics viewer
- refactoring.nvim - Code refactoring tools
- nvim-dap - Debug Adapter Protocol (WIP)
- markdown-preview.nvim - Markdown preview in browser