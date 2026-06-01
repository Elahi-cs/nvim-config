return {
    'mbbill/undotree',
    priority = 1000, -- Load early to ensure autoload functions are available
    lazy = false,
    config = function()
        -- Create our own safer autocommand that checks function availability
        vim.api.nvim_create_augroup('UndotreeSafe', { clear = true })
        vim.api.nvim_create_autocmd('BufReadPost', {
            group = 'UndotreeSafe',
            callback = function()
                -- Only call if function exists
                if vim.fn.exists('*undotree#UndotreePersistUndo') == 1 then
                    vim.fn['undotree#UndotreePersistUndo'](0)
                end
            end,
        })
        
        -- Disable the original autocommand that's causing issues
        vim.cmd('autocmd! undotreeDetectPersistenceUndo')
    end,
}
