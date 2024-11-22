return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			javascript = { "prettierd" },
			javascriptreact = { "prettierd" },
			typescript = { "prettierd" },
			typescriptreact = { "prettierd" },
			json = { { "deno_fmt", "prettierd" } },
			jsonc = { { "deno_fmt", "prettierd" } },
			html = { "prettierd" },
			css = { "prettierd" },
			astro = { "prettierd" },
			svelte = {},
			lua = { "stylua" },
			python = { "black" },
			ocaml = { "ocamlformat" },
			markdown = { "mdformat" },
			templ = { "templ" },
		},
		format_on_save = {
			lsp_format = "fallback",
			timeout = 500,
		}
	},
	config = function(conf)
		require("conform").setup(conf.opts)

		vim.keymap.set("n", "<leader>fm", function()
			require("conform").format({
				lsp_format = "fallback",
			})
		end, { desc = "Format buffer" })
	end,
}
