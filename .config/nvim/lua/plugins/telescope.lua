local __in_git_repo = nil
local function fetch_in_git_repo()
	local success = pcall(function()
		return vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null")
	end)
	return success and vim.v.shell_error == 0
end

local function files()
	if __in_git_repo == nil then
		__in_git_repo = fetch_in_git_repo()
	end

	if __in_git_repo then
		return require("telescope.builtin").git_files()
	else
		return require("telescope.builtin").find_files()
	end
end

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
				},
				git_files = {
					hidden = true,
					show_untracked = true,
				},
			},
		})

		telescope.load_extension("noice")

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>ff", builtin.buffers, { desc = "Find Open Files" })
		vim.keymap.set("n", "<leader><space>", builtin.find_files, { desc = "Find Files" })
		vim.keymap.set("n", "<leader>fg", files, { desc = "Find Files" })
		vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Find in Current Buffer" })
		vim.keymap.set("n", "<leader>fl", builtin.live_grep, { desc = "Find in Files" })
	end,
}
