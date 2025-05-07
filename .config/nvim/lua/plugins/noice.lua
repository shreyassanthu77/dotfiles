return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {},
	config = function()
		-- require("noice").setup({
		-- 	presets = {
		-- 		bottom_search = true,
		-- 		command_palette = false,
		-- 	},
		-- 	lsp = {
		-- 		override = {
		-- 			-- override the default lsp markdown formatter with Noice
		-- 			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
		-- 			-- override the lsp markdown formatter with Noice
		-- 			["vim.lsp.util.stylize_markdown"] = true,
		-- 			-- override cmp documentation with Noice (needs the other options to work)
		-- 			["cmp.entry.get_documentation"] = true,
		-- 		},
		-- 		signature = {
		-- 			auto_open = {
		-- 				enabled = false,
		-- 			}
		-- 		}
		-- 	},
		-- 	routes = {
		-- 		{
		-- 			filter = {
		-- 				event = "msg_show",
		-- 				kind = "",
		-- 				find = "written",
		-- 			},
		-- 			opts = { skip = true },
		-- 		},
		-- 	},
		-- })
	end
}
