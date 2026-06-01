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
