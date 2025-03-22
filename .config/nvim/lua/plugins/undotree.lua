return {
	"jiaoshijie/undotree",
	config = function()
		local ut = require("undotree")
		ut.setup({
			-- float_diff = false,
		})

		vim.keymap.set("n", "<leader>u", ut.toggle, { desc = "Toggle undotree" })
	end,
}
