return {
	"stevearc/conform.nvim",
	opts = {
		-- format_on_save = { async = true, lsp_fallback = true },
		formatters_by_ft = {
			javascript = { { "deno_fmt", "prettierd" } },
			javascriptreact = { { "deno_fmt", "prettierd" } },
			typescript = { { "deno_fmt", "prettierd" } },
			typescriptreact = { { "deno_fmt", "prettierd" } },
			json = { { "deno_fmt", "prettierd" } },
			html = { "prettierd" },
			css = { "prettierd" },
			-- astro = { "prettierd" },
			svelte = { "prettierd" },
			lua = { "stylua" },
			python = { "black" },
			ocaml = { "ocamlformat" },
			markdown = { "mdformat" },
			templ = { "templ" }
		},
	},
	config = function(conf)
		require("conform").setup(conf.opts)

		vim.keymap.set("n", "<leader>fm", function()
			require("conform").format({ async = true, lsp_fallback = true })
		end, { desc = "Format buffer" })
	end,
}
