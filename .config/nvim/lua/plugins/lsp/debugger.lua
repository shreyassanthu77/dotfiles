return {
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"mfussenegger/nvim-dap",
		},
		config = function()
			require("mason-nvim-dap").setup({
				ensure_installed = {
					"codelldb"
				},
				handlers = {}
			})
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			dapui.setup()
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

			-- vim.keymap.set("n", "<leader>da", function()
			-- 	dap.attach({
			-- 		port = vim.fn.input("Port: ", vim.fn.input("Port: ")),
			-- 		type = "server",
			-- 		executable = vim.fn.input("Executable: ", vim.fn.input("Executable: ")),
			--
			-- 	}, {
			-- 		request = "attach",
			-- 	}, {})
			-- end, { desc = "DAP attach" })

			vim.keymap.set("n", "<leader>db", function()
				dap.toggle_breakpoint()
			end, { desc = "DAP set breakpoint" })

			vim.keymap.set("n", "<leader>dc", function()
				dap.continue()
			end, { desc = "DAP continue" })

			vim.keymap.set("n", "<leader>do", function()
				dap.step_over()
			end, { desc = "DAP step over" })

			vim.keymap.set("n", "<leader>di", function()
				dap.step_into()
			end, { desc = "DAP step into" })
		end,

	}
}
