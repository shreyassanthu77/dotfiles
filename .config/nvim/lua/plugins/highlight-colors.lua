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
			outputs = {
				ccc.output.hex
			}
		})
	end
}
