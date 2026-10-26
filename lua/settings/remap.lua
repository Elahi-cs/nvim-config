vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.keymap.set("n", "<leader>pv", "<cmd>Ex<CR>")

-- Move selected lines up or down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Cursor remains in place when appending
vim.keymap.set("n", "J", "mzJ`z")

-- Allows to keep pasted content in register
vim.keymap.set("x", "<leader>p", "\"_dP")

-- Allows yanking inside the plus register (system clipboard)
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

-- Go to config folder
vim.keymap.set("n", "<leader>gcf", "<cmd>Ex ~/.config/nvim/<CR>")

-- Open README file
vim.keymap.set("n", "<leader>rdm", "<cmd>e ~/.config/README.md<CR>")

-- Open this file
vim.keymap.set("n", "<leader>map", "<cmd>e ~/.config/nvim/lua/settings/remap.lua<CR>")

-- C files: build with make. Uses the Makefile in the file's directory if one
-- exists, otherwise make's implicit rule (foo.c -> foo). Errors go to quickfix.
-- Also builds on every save unless disabled: set vim.g.c_make_on_write = false
-- or run :CMakeOnWriteToggle.
if vim.g.c_make_on_write == nil then
    vim.g.c_make_on_write = true
end

local function make_c_file()
    local dir = vim.fn.expand("%:p:h")
    local has_makefile = false
    for _, name in ipairs({ "GNUmakefile", "makefile", "Makefile" }) do
        if vim.fn.filereadable(dir .. "/" .. name) == 1 then
            has_makefile = true
            break
        end
    end
    local target = has_makefile and "" or vim.fn.shellescape(vim.fn.expand("%:t:r"))
    vim.cmd("silent make -C " .. vim.fn.shellescape(dir) .. " " .. target)
    vim.cmd("cwindow")
end

local c_make_group = vim.api.nvim_create_augroup("CMake", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = c_make_group,
    pattern = "c",
    callback = function(ev)
        vim.keymap.set("n", "<leader>cm", function()
            vim.cmd("write")
            -- The save already triggered a build if make-on-write is on
            if not vim.g.c_make_on_write then
                make_c_file()
            end
        end, { buffer = ev.buf, desc = "Save and make current C file" })
    end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
    group = c_make_group,
    pattern = "*.c",
    callback = function()
        if vim.g.c_make_on_write then
            make_c_file()
        end
    end,
})

vim.api.nvim_create_user_command("CMakeOnWriteToggle", function()
    vim.g.c_make_on_write = not vim.g.c_make_on_write
    print("C make on write: " .. (vim.g.c_make_on_write and "on" or "off"))
end, { desc = "Toggle building C files on save" })
