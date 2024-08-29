return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	opts = {
		ensure_installed = {
			"lua",
			"typescript",
			"javascript",
			"tsx",
			"css",
			"html",
			"json",
			"yaml",
			"zig",
			"python",
			"astro",
			"svelte",
			"dart",
			"go",
			"templ",
			"http",
			"ocaml",
			"vimdoc",
		},
		auto_install = false,
		highlight = { enable = true },
		indent = { enable = true },
	},
	build = ":TSUpdate",
	config = function(conf)
		vim.defer_fn(function()
			require("nvim-treesitter.configs").setup(conf.opts)
		end, 0)
	end,
}
