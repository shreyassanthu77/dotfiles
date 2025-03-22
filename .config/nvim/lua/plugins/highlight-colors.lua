-- return {
-- 	"brenoprata10/nvim-highlight-colors",
-- 	opts = {},
-- }
return {
	"uga-rosa/ccc.nvim",
	config = function()
		local ccc = require("ccc")

		ccc.setup({
			highlighter = {
				auto_enable = true,
				lsp = true,
			},
			inputs = {
				ccc.input.hsl,
				ccc.input.hsv,
				ccc.input.rgb,
				ccc.input.oklch,
			},
			outputs = {
				ccc.output.css_rgba,
				ccc.output.hex,
				ccc.output.css_hsl,
				ccc.output.float,
			}
		})

		vim.keymap.set("n", "<leader>hc", function()
			vim.cmd.CccPick()
		end)
	end
}
