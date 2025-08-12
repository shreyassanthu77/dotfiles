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
	{
		"yetone/avante.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
		},
		build = "make",
		event = "VeryLazy",
		version = false, -- Never set this value to "*"! Never!
		---@module 'avante'
		---@type avante.Config
		opts = {
			provider = "gpt_oss_groq",
			providers = {
				kimi_groq = {
					__inherited_from = "openai",
					api_key_name = "cmd:jq '.groq.key' -r ~/.local/share/opencode/auth.json",
					endpoint = "https://api.groq.com/openai/v1/",
					model = "moonshotai/kimi-k2-instruct",
				},
				gpt_oss_groq = {
					__inherited_from = "openai",
					api_key_name = "cmd:jq '.groq.key' -r ~/.local/share/opencode/auth.json",
					endpoint = "https://api.groq.com/openai/v1/",
					model = "openai/gpt-oss-120b",
				}
			},
			windows = {
				sidebar_header = {
					enabled = false,
				}
			},
		},
	}
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
}
