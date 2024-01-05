return {
	"jiaoshijie/undotree",
	config = function()
		local ut = require("undotree")
		ut.setup()

		vim.keymap.set("n", "<leader>u", ut.toggle, { desc = "Toggle undotree" })
	end,
}
