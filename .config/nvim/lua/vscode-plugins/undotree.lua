return {
	"jiaoshijie/undotree",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local ut = require("undotree")
		ut.setup()

		vim.keymap.set("n", "<leader>u", ut.toggle, { desc = "Toggle undotree" })
	end,
}
