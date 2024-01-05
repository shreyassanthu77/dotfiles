return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-ui-select.nvim",
	},
	opts = function()
		return {
			["ui-select"] = {
				require("telescope.themes").get_cursor(),
			},
		}
	end,
	config = function(conf)
		local telescope = require("telescope")
		telescope.setup(conf.opts())
		telescope.load_extension("ui-select")

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>ff", builtin.buffers, { desc = "Find Open Files" })
		vim.keymap.set("n", "<leader><space>", builtin.find_files, { desc = "Find Files" })
		vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "Find Git Files" })
	end,
}
