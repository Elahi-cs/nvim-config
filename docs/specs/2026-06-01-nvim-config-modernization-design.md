# Neovim Config Modernization — Design

**Date:** 2026-06-01
**Status:** Approved (pre-implementation)

## Problem

The current hand-rolled Neovim config (lazy.nvim, Neovim 0.11.2) has four pain points:

1. **Python LSP broken.** Opening a `.py` file produces a Ruff error and no working language
   features. Root cause: `pyright-langserver` is **not installed** on the system. Ruff *is*
   installed, but Ruff is a linter/formatter and provides no go-to-definition — so the only server
   that starts is Ruff, which is what throws the error.
2. **`gd` (go-to-definition) doesn't work.** Same root cause: the server that supplies definitions
   (pyright) never starts because its binary is missing. `gd` is correctly mapped in the `LspAttach`
   autocommand; it simply has no provider.
3. **No Python debugging.** `nvim-dap` is absent from the active config and `debugpy` is not
   installed, so the user falls back to PyCharm. (A nested duplicate config tree contains unused DAP
   files.)
4. **Messy, poorly documented directory.** A full duplicate config is nested at `nvim/` (54 files
   tracked in git, including `old_config/` and `old_old_config/`), `test_lsp.py` sits at the repo
   root, and `nvim-lspconfig` is installed but unused (LSP is hand-configured in `init.lua`).
   Plugin config is split between `lua/packages/*.lua` (specs) and `after/plugin/*.lua` (config),
   which loads eagerly and fights lazy.nvim's lazy-loading.

## Goals

- Python LSP works: `gd`, `gr`, `K`, rename, completion — all functional, no Ruff error.
- Python debugging available inside Neovim (breakpoints, stepping, variable inspection, REPL).
- Clean, documented, single-source directory structure following lazy.nvim idioms.
- Fresh clone "just works" without manual per-tool installs.

## Decisions (from brainstorming)

- **Direction:** keep the hand-rolled, modular config; modernize it. No distribution (LazyVim) and
  no kickstart rebase.
- **Binary management:** use **Mason** (`mason.nvim` + `mason-tool-installer`). Mason is a binary
  installer, orthogonal to Neovim 0.11's built-in LSP (which only *configures/launches* servers).
  It provides reproducible, Neovim-managed installs.
- **Cleanup:** delete the nested `nvim/` tree, `old_config/`, `old_old_config/`, and `test_lsp.py`
  outright (git history preserves them).
- **Structure:** collapse `after/plugin/*.lua` into the per-plugin specs in `lua/packages/`.
- **Languages:** Python is the focus (full LSP + treesitter + debugging). Go's existing gopls LSP is
  retained as-is (no regression), with no Go debugging added. No `lua_ls` (user plans to stop
  editing Lua config once this works).

## Design

### 1. Directory structure

Fold each plugin's `after/plugin/` config into its `lua/packages/` spec (lazy.nvim idiom:
`config`/`opts`/`keys`/`event` live with the spec). Move the LSP block out of `init.lua` into a
dedicated config file. Delete the duplicate/old trees.

```
~/.config/nvim/
├── init.lua                # bootstrap lazy + require("settings") + require("config.lsp")
├── lua/
│   ├── settings/
│   │   ├── init.lua        # requires global + remap (unchanged)
│   │   ├── global.lua      # options
│   │   └── remap.lua       # core, non-plugin keymaps
│   ├── config/
│   │   └── lsp.lua         # vim.lsp.config/enable + LspAttach keymaps (moved out of init.lua)
│   └── packages/           # one file per plugin: spec + config together
│       ├── mason.lua       # NEW: mason + mason-tool-installer
│       ├── completion.lua  # merges existing nvim-cmp.lua + after/plugin/cmp.lua
│       ├── dap.lua         # NEW: nvim-dap + nvim-dap-ui + nvim-dap-python
│       ├── lsp.lua         # nvim-lspconfig (kept, used the 0.11 way)
│       ├── telescope.lua
│       ├── treesitter.lua
│       ├── harpoon.lua
│       ├── undotree.lua
│       ├── fugitive.lua
│       ├── trouble.lua
│       ├── refactoring.lua
│       ├── themes.lua
│       └── markdown.lua
└── docs/specs/             # this spec
```

Deleted: `after/plugin/` (entire directory), `nvim/`, `nvim/old_config/`, `nvim/old_old_config/`,
`test_lsp.py`.

### 2. LSP fix

**a) Mason installs the binaries.** `lua/packages/mason.lua` adds `mason.nvim` +
`mason-tool-installer` with `ensure_installed = { "pyright", "ruff", "debugpy" }`. gopls remains a
system install. On first launch Mason fetches the tools into Neovim's data dir and puts them on the
runtime path.

**b) Use `nvim-lspconfig` the 0.11 way.** In Neovim 0.11, `nvim-lspconfig` ships the `lsp/*.lua`
default configs (`cmd`, `filetypes`, `root_dir`) that `vim.lsp.enable()` reads automatically.
`lua/config/lsp.lua` therefore reduces to: shared capabilities, per-server *setting overrides only*
(no manual `cmd`/`filetypes`), and `vim.lsp.enable({ "pyright", "ruff", "gopls" })`. This removes the
"installed but unused" smell.

**c) Capabilities + Ruff/pyright split.**
- Merge `cmp-nvim-lsp` capabilities into the shared `vim.lsp.config('*')` block (currently just
  `make_client_capabilities()`).
- Disable Ruff's `hover` provider so pyright owns hover/`K`; Ruff owns lint/format. Standard
  pyright+ruff division of labor.

**LspAttach keymaps** (carried over, unchanged): `gd`, `gD`, `gi`, `gr`, `K`, `<leader>rn`.

### 3. Python debugging

`lua/packages/dap.lua` bundles:
- `mfussenegger/nvim-dap` — debug engine.
- `rcarriga/nvim-dap-ui` (+ `nvim-nio`) — UI for variables, scopes, watches, call stack, REPL;
  auto-opens on session start, closes on exit.
- `mfussenegger/nvim-dap-python` — wires DAP to the Mason-installed `debugpy`; adds Python-aware
  launchers (debug nearest test, debug method).

Keymaps (`<leader>d…`):

| Key | Action |
|-----|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue / start |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dr` | Open REPL |
| `<leader>du` | Toggle DAP-UI |
| `<leader>dt` | Debug nearest Python test |
| `<leader>dx` | Terminate session |

### 4. Documentation

- **Rewrite `README.md`:** install steps, Mason-managed prerequisites (`node` for pyright, system
  `python3`), full keymap reference (core + LSP + DAP), and a short "how the config is organized"
  map.
- **Update `CLAUDE.md`:** describe the new structure (currently documents the manual-`cmd` LSP setup
  and omits DAP, completion, and Mason).
- One-line header comment in each `lua/packages/*.lua` and in `lua/config/lsp.lua` stating its job.

## Out of scope

- Go debugging (Delve).
- `lua_ls` and Lua config tooling.
- Adopting a distribution or kickstart base.
- Any new language support beyond Python/Go.

## Success criteria

1. Opening a `.py` file starts pyright + ruff with no error message.
2. `gd`, `gr`, `K`, and `<leader>rn` work in Python files.
3. Setting a breakpoint and `<leader>dc` launches a debug session with the DAP-UI showing
   variables/stack; `<leader>dt` debugs the nearest test.
4. `after/plugin/`, nested `nvim/`, old config trees, and `test_lsp.py` are gone; each active plugin
   has a single spec file with its config inline.
5. README and CLAUDE.md accurately describe the new layout and keymaps.
