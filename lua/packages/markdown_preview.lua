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
