return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			defaults = {
				winblend = vim.g.neovide and 80 or 0,
			},
			pickers = {
				find_files = {
					hidden = true,
				},
				live_grep = {
					hidden = true,
				}
			},
		})

		telescope.load_extension("noice")

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>ff", builtin.buffers, { desc = "Find Open Files" })
		vim.keymap.set("n", "<leader><space>", builtin.find_files, { desc = "Find Files" })
		vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Find in Current Buffer" })
		vim.keymap.set("n", "<leader>fl", builtin.live_grep, { desc = "Find in Files" })
	end,
}
