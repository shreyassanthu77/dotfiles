return {
	'nvim-flutter/flutter-tools.nvim',
	lazy = false,
	dependencies = {
		'nvim-lua/plenary.nvim',
		'stevearc/dressing.nvim',
	},
	config = function()
		local flutter = require('flutter-tools')
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		local on_attach = require("plugins/lsp/lsp_attach")


		flutter.setup({
			lsp = {
				cpaabilities = capabilities,
				on_attach = on_attach,
			}
		})
	end
}
