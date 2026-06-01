# Neovim Config Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the Python LSP (`gd`/hover), add Python debugging, and clean up the directory of a hand-rolled Neovim (0.11.2) config.

**Architecture:** Keep the hand-rolled lazy.nvim config but (a) collapse `after/plugin/*.lua` into the per-plugin specs in `lua/packages/`, (b) move LSP setup into `lua/config/lsp.lua` using Neovim 0.11's built-in client with `nvim-lspconfig` supplying defaults, (c) add Mason to install `pyright`/`ruff`/`debugpy`, (d) add `nvim-dap` + `nvim-dap-ui` + `nvim-dap-python`, and (e) delete the duplicate/old config trees.

**Tech Stack:** Neovim 0.11.2, lazy.nvim, nvim-lspconfig, mason.nvim + mason-tool-installer, nvim-cmp + LuaSnip, nvim-dap + nvim-dap-ui + nvim-dap-python, pyright, ruff, debugpy.

**Verification note:** This is a config repo with no test framework, so tasks verify via `nvim --headless` commands and explicit manual checks rather than unit tests. Commit after each task.

---

## File Structure

**Create:**
- `lua/config/lsp.lua` — built-in LSP setup (capabilities, per-server settings, LspAttach keymaps, enable). Moved out of `init.lua`.
- `lua/packages/mason.lua` — `mason.nvim` + `mason-tool-installer` spec; ensures pyright/ruff/debugpy.
- `lua/packages/completion.lua` — merged `nvim-cmp` spec + config (replaces `lua/packages/nvim-cmp.lua` and `after/plugin/cmp.lua`).
- `lua/packages/dap.lua` — `nvim-dap` + `nvim-dap-ui` + `nvim-dap-python` spec + config + keymaps.
- `scripts/healthcheck.sh` — bundles the headless verification checks so a fresh install can be tested in one command.

**Modify (fold `after/plugin` config into the spec's `config`/`keys`):**
- `lua/packages/telescope.lua`, `lua/packages/treesitter.lua`, `lua/packages/harpoon.lua`, `lua/packages/undotree.lua`, `lua/packages/fugitive.lua`, `lua/packages/markdown_preview.lua`
- `lua/packages/lsp.lua` (rename concept: it already holds `nvim-lspconfig`; add a header comment)
- `init.lua` (remove inline LSP block; `require('config.lsp')`)
- `README.md`, `CLAUDE.md` (docs)

**Delete:**
- `nvim/` (entire nested duplicate tree — 54 tracked files incl. `old_config/`, `old_old_config/`)
- `test_lsp.py`
- `after/plugin/` (entire directory, after folding)
- `lua/packages/nvim-cmp.lua` (replaced by `completion.lua`)

**Leave as-is:** `lua/packages/refactoring.lua` (`enabled = false`), `trouble.lua`, `themes.lua`, `core.lua`, `luarocks.lua`, `vim-swagger-preview.lua`, `lua/settings/*`.

**Keymap decision:** telescope `git_files` moves from `<C-p>` to `<leader>pg` to resolve the clash with harpoon's slot-4 `<C-p>`. Harpoon's `<C-h/n/l/p>` are preserved.

---

## Task 1: Delete duplicate and stale files

**Files:**
- Delete: `nvim/` (tracked), `test_lsp.py` (untracked)

- [ ] **Step 1: Confirm what will be deleted**

Run: `git ls-files nvim/ | wc -l && ls test_lsp.py`
Expected: a count of `54` and `test_lsp.py` listed.

- [ ] **Step 2: Delete the nested tracked tree**

Run:
```bash
git rm -r nvim/
```
Expected: "rm 'nvim/...'" lines, 54 files removed.

- [ ] **Step 3: Delete the untracked scratch file**

Run:
```bash
rm -f test_lsp.py
```
Expected: no output.

- [ ] **Step 4: Verify the working tree no longer has them**

Run: `test ! -e nvim && test ! -e test_lsp.py && echo CLEAN`
Expected: `CLEAN`

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Remove nested duplicate config and scratch test file"
```

---

## Task 2: Add Mason to install Python tooling

**Files:**
- Create: `lua/packages/mason.lua`

- [ ] **Step 1: Create the Mason spec**

Create `lua/packages/mason.lua`:
```lua
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
```

- [ ] **Step 2: Sync plugins so Mason installs**

Run:
```bash
nvim --headless "+Lazy! sync" "+MasonToolsInstallSync" +qa
```
Expected: lazy.nvim installs the plugins; mason-tool-installer installs pyright, ruff, debugpy (may take a minute). No fatal errors printed.

- [ ] **Step 3: Verify the binaries exist under Mason**

Run:
```bash
ls ~/.local/share/nvim/mason/bin/ | grep -E 'pyright|ruff'
test -x ~/.local/share/nvim/mason/packages/debugpy/venv/bin/python && echo DEBUGPY_OK
```
Expected: `pyright-langserver` (and `ruff`) listed, and `DEBUGPY_OK`.

- [ ] **Step 4: Commit**

```bash
git add lua/packages/mason.lua
git commit -m "Add Mason to install pyright, ruff, debugpy"
```

---

## Task 3: Move LSP config into lua/config/lsp.lua (0.11 way)

**Files:**
- Create: `lua/config/lsp.lua`
- Modify: `init.lua` (remove inline LSP block, require the new module)
- Modify: `lua/packages/lsp.lua` (`nvim-lspconfig` — add header comment only)

- [ ] **Step 1: Create `lua/config/lsp.lua`**

Create `lua/config/lsp.lua`:
```lua
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

-- Python: ruff owns lint + format (hover disabled on attach below).
vim.lsp.config("ruff", {})

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
```

- [ ] **Step 2: Remove the inline LSP block from `init.lua` and require the module**

In `init.lua`, replace everything from the line `-- lua/packages/lsp.lua` (currently line 29) through the final `vim.lsp.enable({ 'ruff', 'gopls', 'pyright' })` with a single require. The resulting `init.lua` tail should read:
```lua
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = "packages",
})

-- Set colorscheme
vim.opt.termguicolors = true

-- LSP configuration (Neovim 0.11+ built-in client)
require("config.lsp")
```
Leave the lazy.nvim bootstrap block (lines 1–24) unchanged.

- [ ] **Step 3: Add a header comment to `lua/packages/lsp.lua`**

Replace the contents of `lua/packages/lsp.lua` (currently `nvim-lspconfig.lua`; confirm the actual filename with `git ls-files lua/packages | grep lsp`) with:
```lua
-- nvim-lspconfig: supplies the per-server default configs that Neovim 0.11's
-- vim.lsp.enable() consumes. Actual server settings live in lua/config/lsp.lua.
return {
    "neovim/nvim-lspconfig",
    lazy = false,
}
```
Note: the existing file is named `lua/packages/nvim-lspconfig.lua`. Keep that filename; only its body changes.

- [ ] **Step 4: Verify the config loads without errors**

Run:
```bash
nvim --headless "+lua require('config.lsp'); print('LSP_LOADED_OK')" +qa
```
Expected: prints `LSP_LOADED_OK` with no error traceback.

- [ ] **Step 5: Manual check — Python LSP attaches and `gd` works**

Create a scratch file and open it:
```bash
printf 'import os\n\n\ndef greet(name):\n    return "hi " + name\n\n\nprint(greet("x"))\nprint(os.getcwd())\n' > /tmp/lsp_check.py
nvim /tmp/lsp_check.py
```
In Neovim:
1. Run `:LspInfo` (or `:checkhealth vim.lsp`) — expect **pyright** and **ruff** attached, no error popup.
2. Put the cursor on `greet` in the last `print(greet(...))` line and press `gd` — cursor should jump to the `def greet` definition.
3. Press `K` on `os` — a hover doc popup should appear (from pyright, not a ruff error).
4. `:q`

- [ ] **Step 6: Commit**

```bash
git add init.lua lua/config/lsp.lua lua/packages/nvim-lspconfig.lua
git commit -m "Move LSP setup to lua/config/lsp.lua; fix pyright + ruff split"
```

---

## Task 4: Merge nvim-cmp into a single completion spec

**Files:**
- Create: `lua/packages/completion.lua`
- Delete: `lua/packages/nvim-cmp.lua`, `after/plugin/cmp.lua`

- [ ] **Step 1: Create `lua/packages/completion.lua`**

Create `lua/packages/completion.lua` (spec from the old `nvim-cmp.lua` + config from `after/plugin/cmp.lua`):
```lua
-- Autocompletion: nvim-cmp with LSP, buffer, path sources and LuaSnip snippets.
return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
    },
    config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")

        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<C-e>"] = cmp.mapping.abort(),
                ["<CR>"] = cmp.mapping.confirm({ select = true }),
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
            }),
            sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "luasnip" },
            }, {
                { name = "buffer" },
                { name = "path" },
            }),
        })
    end,
}
```

> Note: `<C-e>` is bound here (cmp abort, insert mode only) and also by harpoon (normal mode quick-menu). Different modes — no conflict.

- [ ] **Step 2: Delete the now-redundant files**

Run:
```bash
rm -f lua/packages/nvim-cmp.lua after/plugin/cmp.lua
```
Expected: no output.

- [ ] **Step 3: Verify completion loads**

Run:
```bash
nvim --headless "+Lazy! load nvim-cmp" "+lua require('cmp'); print('CMP_OK')" +qa
```
Expected: prints `CMP_OK` with no error.

- [ ] **Step 4: Manual check — completion popup appears**

Run `nvim /tmp/lsp_check.py`, enter insert mode at end of file, type `os.` and confirm an LSP completion menu lists `getcwd`, etc. `:q!`

- [ ] **Step 5: Commit**

```bash
git add lua/packages/completion.lua
git add -A
git commit -m "Merge nvim-cmp spec and config into completion.lua"
```

---

## Task 5: Fold remaining after/plugin configs into their specs

**Files:**
- Modify: `lua/packages/telescope.lua`, `treesitter.lua`, `harpoon.lua`, `undotree.lua`, `fugitive.lua`, `markdown_preview.lua`
- Delete: `after/plugin/` (entire directory)

- [ ] **Step 1: Update `lua/packages/telescope.lua`**

Replace its contents (moves keymaps in; `git_files` rebound to `<leader>pg`):
```lua
-- Fuzzy finder. Keymaps moved here from after/plugin/telescope.lua.
return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    config = function()
        local builtin = require("telescope.builtin")
        vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "Telescope: find files" })
        vim.keymap.set("n", "<leader>pg", builtin.git_files, { desc = "Telescope: git files" })
        vim.keymap.set("n", "<leader>ps", function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end, { desc = "Telescope: grep" })
        vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "Telescope: LSP references" })
    end,
}
```

- [ ] **Step 2: Update `lua/packages/treesitter.lua`**

Replace its contents (fold the setup in):
```lua
-- Syntax highlighting / parsing. Setup moved here from after/plugin/treesitter.lua.
return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = function()
        require("nvim-treesitter.install").update({ with_sync = true })
    end,
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = { "javascript", "json", "lua", "vim", "python", "vimdoc", "query" },
            sync_install = false,
            auto_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
        })
    end,
}
```

- [ ] **Step 3: Update `lua/packages/harpoon.lua`**

Replace its contents (fold setup + keymaps in; slot-4 `<C-p>` preserved):
```lua
-- Quick file navigation. Setup + keymaps moved here from after/plugin/harpoon.lua.
return {
    "theprimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup()

        vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
        vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
        vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
        vim.keymap.set("n", "<C-n>", function() harpoon:list():select(2) end)
        vim.keymap.set("n", "<C-l>", function() harpoon:list():select(3) end)
        vim.keymap.set("n", "<C-p>", function() harpoon:list():select(4) end)
    end,
}
```

- [ ] **Step 4: Update `lua/packages/undotree.lua`**

Add the keymap to the existing spec via a `keys` field. Replace its contents:
```lua
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
```

- [ ] **Step 5: Update `lua/packages/fugitive.lua`**

Replace its contents:
```lua
-- Git integration. Keymap moved here from after/plugin/fugitive.lua.
return {
    "tpope/vim-fugitive",
    lazy = false,
    config = function()
        vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git status" })
    end,
}
```

- [ ] **Step 6: Update `lua/packages/markdown_preview.lua`**

Replace its contents (add keymaps via `keys` so it still lazy-loads on `ft`):
```lua
-- Markdown preview in browser. Keymaps moved here from after/plugin/markdown_preview.lua.
return {
    "iamcco/markdown-preview.nvim",
    build = function() vim.fn["mkdp#util#install"]() end,
    init = function() vim.g.mkdp_filetypes = { "markdown" } end,
    ft = { "markdown" },
    keys = {
        { "<leader>mdp", "<cmd>silent :MarkdownPreview<CR>", desc = "Markdown preview" },
        { "<leader>mdps", "<cmd>silent :MarkdownPreviewStop<CR>", desc = "Stop markdown preview" },
    },
}
```

- [ ] **Step 7: Delete the after/plugin directory**

Run:
```bash
rm -rf after/plugin
test ! -e after/plugin && echo AFTER_PLUGIN_GONE
```
Expected: `AFTER_PLUGIN_GONE`. (The `after/` directory may now be empty; remove it too if so: `rmdir after 2>/dev/null || true`.)

- [ ] **Step 8: Verify everything still loads**

Run:
```bash
nvim --headless "+Lazy! sync" "+lua print('STARTUP_OK')" +qa
```
Expected: `STARTUP_OK`, no error tracebacks.

- [ ] **Step 9: Manual check — keymaps work**

Run `nvim /tmp/lsp_check.py` and confirm: `<leader>pf` opens Telescope find-files, `<leader>u` toggles undotree, `<C-e>` opens the harpoon menu. `:qa!`

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "Fold after/plugin configs into plugin specs; remove after/plugin"
```

---

## Task 6: Add Python debugging (nvim-dap)

**Files:**
- Create: `lua/packages/dap.lua`

- [ ] **Step 1: Create `lua/packages/dap.lua`**

Create `lua/packages/dap.lua`:
```lua
-- Python debugging: nvim-dap engine + dap-ui + dap-python (uses Mason's debugpy).
return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "mfussenegger/nvim-dap-python",
    },
    keys = {
        { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP: Toggle breakpoint" },
        { "<leader>dc", function() require("dap").continue() end, desc = "DAP: Continue" },
        { "<leader>di", function() require("dap").step_into() end, desc = "DAP: Step into" },
        { "<leader>do", function() require("dap").step_over() end, desc = "DAP: Step over" },
        { "<leader>dO", function() require("dap").step_out() end, desc = "DAP: Step out" },
        { "<leader>dr", function() require("dap").repl.open() end, desc = "DAP: Open REPL" },
        { "<leader>du", function() require("dapui").toggle() end, desc = "DAP: Toggle UI" },
        { "<leader>dt", function() require("dap-python").test_method() end, desc = "DAP: Debug nearest test" },
        { "<leader>dx", function() require("dap").terminate() end, desc = "DAP: Terminate" },
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")
        dapui.setup()

        -- Use the debugpy interpreter that Mason installed.
        local debugpy_python = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
        require("dap-python").setup(debugpy_python)

        -- Open / close the UI automatically with the debug session.
        dap.listeners.before.attach.dapui_config = function() dapui.open() end
        dap.listeners.before.launch.dapui_config = function() dapui.open() end
        dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
        dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
    end,
}
```

- [ ] **Step 2: Sync plugins**

Run:
```bash
nvim --headless "+Lazy! sync" +qa
```
Expected: nvim-dap, nvim-dap-ui, nvim-nio, nvim-dap-python installed, no fatal errors.

- [ ] **Step 3: Verify DAP modules load and debugpy path is valid**

Run:
```bash
nvim --headless "+Lazy! load nvim-dap" "+lua require('dap'); require('dapui'); require('dap-python').setup(vim.fn.stdpath('data')..'/mason/packages/debugpy/venv/bin/python'); print('DAP_OK')" +qa
```
Expected: prints `DAP_OK` with no error.

- [ ] **Step 4: Manual check — debug a Python file**

Run `nvim /tmp/lsp_check.py`. Then:
1. Move cursor to the `return "hi " + name` line; press `<leader>db` — a breakpoint sign appears.
2. Press `<leader>dc` — the dap-ui panels open (scopes/stack) and execution stops at the breakpoint.
3. Press `<leader>do` to step over; inspect a variable in the Scopes pane.
4. Press `<leader>dx` to terminate; UI closes. `:qa!`

- [ ] **Step 5: Commit**

```bash
git add lua/packages/dap.lua
git commit -m "Add Python debugging via nvim-dap, dap-ui, dap-python"
```

---

## Task 7: Healthcheck script

**Files:**
- Create: `scripts/healthcheck.sh`

- [ ] **Step 1: Create `scripts/healthcheck.sh`**

Create `scripts/healthcheck.sh`:
```bash
#!/usr/bin/env bash
# Healthcheck for this Neovim config. Run after a fresh install:
#   ./scripts/healthcheck.sh
# Runs the headless verification checks and reports pass/fail. Interactive
# behaviors (gd jump, breakpoints, hover) still need the manual smoke test
# documented in README.md.
set -u

NVIM="${NVIM:-nvim}"
DATA="$("$NVIM" --headless "+lua io.write(vim.fn.stdpath('data'))" +qa 2>/dev/null)"
pass=0
fail=0

check() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        printf '  ok    %s\n' "$name"; pass=$((pass + 1))
    else
        printf '  FAIL  %s\n' "$name"; fail=$((fail + 1))
    fi
}

echo "Neovim config healthcheck"
echo "data dir: $DATA"
echo

check "neovim 0.11+"                "$NVIM" --headless "+lua assert(vim.fn.has('nvim-0.11') == 1)" +qa
check "config + LSP module loads"   "$NVIM" --headless "+lua require('config.lsp')" +qa
check "nvim-cmp loads"              "$NVIM" --headless "+Lazy! load nvim-cmp" "+lua require('cmp')" +qa
check "dap modules load"            "$NVIM" --headless "+Lazy! load nvim-dap" "+lua require('dap'); require('dapui'); require('dap-python')" +qa
check "pyright-langserver present"  test -x "$DATA/mason/bin/pyright-langserver"
check "ruff present"                test -e "$DATA/mason/bin/ruff"
check "debugpy present"             test -x "$DATA/mason/packages/debugpy/venv/bin/python"
check "clean startup"               "$NVIM" --headless "+lua print('ok')" +qa

echo
echo "passed: $pass  failed: $fail"
if [ "$fail" -ne 0 ]; then
    echo "Some checks failed. If tools are missing, open nvim and run :MasonToolsInstall."
    exit 1
fi
echo "All headless checks passed. Now run the manual smoke test in README.md."
```

- [ ] **Step 2: Make it executable**

Run:
```bash
chmod +x scripts/healthcheck.sh
```
Expected: no output.

- [ ] **Step 3: Run it**

Run:
```bash
./scripts/healthcheck.sh
```
Expected: every line prints `ok`, ends with `passed: 8  failed: 0` and "All headless checks passed."

- [ ] **Step 4: Commit**

```bash
git add scripts/healthcheck.sh
git commit -m "Add healthcheck script for fresh-install verification"
```

---

## Task 8: Documentation

**Files:**
- Modify: `README.md`, `CLAUDE.md`

- [ ] **Step 1: Rewrite `README.md`**

Replace `README.md` with content covering: install steps, prerequisites, structure map, and keymaps. Use this template (adjust prose, keep the tables accurate to the keymaps defined in Tasks 3–6):
```markdown
# Neovim Configuration

A hand-rolled, modular Neovim (0.11+) config using lazy.nvim.

## Install

```bash
git clone <this-repo> ~/.config/nvim
nvim   # lazy.nvim bootstraps; Mason installs pyright/ruff/debugpy on first launch
```

### Prerequisites
- Neovim 0.11+
- `node` (runtime for pyright) and system `python3`
- `go` toolchain with `gopls` on PATH (for Go LSP)
- LSP/debug binaries (pyright, ruff, debugpy) are installed automatically by Mason.

### Verify the install
```bash
./scripts/healthcheck.sh   # runs the headless checks
```
Then do the manual smoke test (open a `.py` file; check `gd`, `K`, a breakpoint).

## Structure

- `init.lua` — bootstraps lazy.nvim, loads settings, requires `config.lsp`
- `lua/settings/` — options (`global.lua`) and core keymaps (`remap.lua`)
- `lua/config/lsp.lua` — built-in LSP setup (capabilities, server settings, keymaps)
- `lua/packages/` — one file per plugin: lazy.nvim spec + its config inline

## Keymaps

Leader is `<Space>`.

### Files / search
| Key | Action |
|-----|--------|
| `<leader>pv` | File explorer (netrw) |
| `<leader>pf` | Telescope find files |
| `<leader>pg` | Telescope git files |
| `<leader>ps` | Telescope grep |
| `<C-e>` | Harpoon quick menu |
| `<leader>a` | Harpoon add file |
| `<C-h>/<C-n>/<C-l>/<C-p>` | Harpoon slots 1–4 |
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
```

- [ ] **Step 2: Update `CLAUDE.md`**

In `CLAUDE.md`, update the **LSP Configuration** section and **Major Plugins** to reflect the new reality. Replace the "LSP Configuration" bullet list with:
```markdown
### LSP Configuration
- Neovim 0.11+ built-in LSP, configured in `lua/config/lsp.lua` (not inline in init.lua)
- `nvim-lspconfig` supplies per-server defaults (cmd/filetypes/root_dir); `lua/config/lsp.lua` overrides capabilities + settings and calls `vim.lsp.enable()`
- Server binaries (pyright, ruff, debugpy) are installed via Mason (`lua/packages/mason.lua`)
- Python: pyright provides definitions/hover/types; ruff provides lint/format (hover disabled)
- Enabled servers: pyright, ruff, gopls
```
And add to the Major Plugins list:
```markdown
- mason.nvim + mason-tool-installer - external tool (LSP/DAP) installer
- nvim-cmp - autocompletion (config in lua/packages/completion.lua)
- nvim-dap + nvim-dap-ui + nvim-dap-python - Python debugging
```
Also update the **Key Leader Mappings** section: change `<leader>ps` description if needed and note `<leader>pg` for git files. Update the "after/plugin/" references — configs now live inline in `lua/packages/`, and the `after/plugin/` directory no longer exists.

- [ ] **Step 3: Verify docs reference real keymaps**

Run:
```bash
grep -q "leader>pg" README.md && grep -q "config/lsp.lua" CLAUDE.md && echo DOCS_OK
```
Expected: `DOCS_OK`

- [ ] **Step 4: Commit**

```bash
git add README.md CLAUDE.md
git commit -m "Update README and CLAUDE.md for modernized config"
```

---

## Final verification

- [ ] **Full startup check**

Run:
```bash
nvim --headless "+Lazy! sync" "+lua print('FINAL_OK')" +qa
```
Expected: `FINAL_OK`, no error tracebacks.

- [ ] **Run the healthcheck script**

Run:
```bash
./scripts/healthcheck.sh
```
Expected: `passed: 8  failed: 0`.

- [ ] **End-to-end manual smoke test**

`nvim /tmp/lsp_check.py` and confirm against the spec's success criteria:
1. No Ruff error on open; `:LspInfo` shows pyright + ruff attached.
2. `gd` jumps to definition; `K` shows hover; `<leader>rn` renames.
3. `<leader>db` + `<leader>dc` starts a debug session with the UI; `<leader>dt` debugs a test.
4. `after/plugin/`, nested `nvim/`, and `test_lsp.py` are gone (`ls` to confirm).
5. README and CLAUDE.md match the new layout.

Then clean up the scratch file: `rm -f /tmp/lsp_check.py`
```
```
