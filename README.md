# Neovim Configuration

A hand-rolled, modular Neovim (0.11+) config using lazy.nvim.

## Install

```bash
git clone <this-repo> ~/.config/nvim
nvim   # lazy.nvim bootstraps and installs plugins on first launch
```

On the first launch, Mason installs the LSP/debug binaries (pyright, ruff,
debugpy) asynchronously in the background. This can take a minute, and a slow
machine may need a second `nvim` start (or `:MasonToolsInstall`) to finish.

### Prerequisites
- Neovim 0.11+
- `node` (runtime for pyright) and system `python3`
- `go` toolchain with `gopls` on PATH (for Go LSP)
- LSP/debug binaries (pyright, ruff, debugpy) are installed automatically by Mason.

### Verify the install
```bash
./scripts/healthcheck.sh   # runs the headless checks
```
Then do the manual smoke test: open a `.py` file and confirm `gd` (go to
definition), `K` (hover), and a breakpoint + `<leader>dc` all work.

## Structure

- `init.lua` - bootstraps lazy.nvim, loads settings, requires `config.lsp`
- `lua/settings/` - options (`global.lua`) and core keymaps (`remap.lua`)
- `lua/config/lsp.lua` - built-in LSP setup (capabilities, server settings, keymaps)
- `lua/packages/` - one file per plugin: lazy.nvim spec + its config inline
- `scripts/healthcheck.sh` - headless verification for a fresh install

## Keymaps

Leader is `<Space>`.

### Files / search
| Key | Action |
|-----|--------|
| `<leader>pv` | File explorer (netrw) |
| `<leader>pf` | Telescope find files |
| `<leader>pg` | Telescope git files |
| `<leader>ps` | Telescope grep |
| `<leader>fr` | Telescope LSP references |
| `<leader>a` | Harpoon add file |
| `<C-e>` | Harpoon quick menu |
| `<C-h>` / `<C-n>` / `<C-l>` / `<C-p>` | Harpoon slots 1-4 |
| `<leader>u` | Toggle undotree |

### LSP
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `gr` | References |
| `K` | Hover docs |
| `<leader>rn` | Rename symbol |

### Debugging (Python)
| Key | Action |
|-----|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue / start |
| `<leader>di` / `<leader>do` / `<leader>dO` | Step into / over / out |
| `<leader>dr` | Open REPL |
| `<leader>du` | Toggle DAP UI |
| `<leader>dt` | Debug nearest test |
| `<leader>dx` | Terminate |

### Git
| Key | Action |
|-----|--------|
| `<leader>gs` | Git status (fugitive) |
