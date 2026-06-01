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
