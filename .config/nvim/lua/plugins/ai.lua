local function map(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { desc = desc, expr = true })
end

return {
	{
		"supermaven-inc/supermaven-nvim",
		config = function()
			require("supermaven-nvim").setup({
				log_level = "off",
				disable_keymaps = false,
				keymaps = {
					accept_suggestion = "<A-a>",
					accept_word = "<A-w>",
					clear_suggestion = "<A-d>",
				},
			})
		end,
	},
	-- {
	-- 	'Exafunction/codeium.vim',
	-- 	event = 'BufEnter',
	-- 	config = function()
	-- vim.g.codeium_disable_bindings = 1
	-- local codeium = function(name)
	-- 	return vim.fn["codeium#" .. name]
	-- end
	--
	-- local accept = codeium("Accept")
	-- local clear = codeium("Clear")
	-- local cycle = codeium("CycleCompletions")
	-- map("i", "<A-a>", function()
	-- 	local fn = vim.fn["codeium#Accept"]
	-- 	fn()
	-- end, "Accept suggestion")
	-- map("i", "<A-d>", clear, "Dismiss suggestion")
	-- map("i", "<A-j>", function()
	-- 	cycle(1)
	-- end, "Next suggestion")
	-- 	end
	-- },
	-- {
	-- 	"zbirenbaum/copilot.lua",
	-- 	config = function()
	-- 		require("copilot").setup({
	-- 			panel = { enabled = false },
	-- 			suggestion = {
	-- 				auto_trigger = true,
	-- 				keymap = {
	-- 					next = "<A-j>",
	-- 					accept = "<A-a>",
	-- 					dismiss = "<A-d>",
	-- 				},
	-- 			},
	-- 			filetypes = {
	-- 				markdown = true,
	-- 				yaml = true,
	-- 			},
	-- 		})
	-- 	end
	-- },
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = false,
		version = false, -- set this if you want to always pull the latest change
		build = "make BUILD_FROM_SOURCE=true",
		dependencies = {
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
			{
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
						use_absolute_path = true,
					},
				},
			},
			{
				'MeanderingProgrammer/render-markdown.nvim',
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
			},
		},

		config = function()
			-- require("avante").setup {
			-- 	provider = "claude",
			-- 	auto_suggestions_provider = "claude",
			-- 	claude = {},
			-- }
		end,
	},
}
