return {
	"rest-nvim/rest.nvim",
	dependencies = { { "nvim-lua/plenary.nvim" } },
	config = function()
		require("rest-nvim").setup({

		})

		vim.api.nvim_create_autocmd({ "BufEnter" }, {
			pattern = { "*.http", "*.rest" },
			callback = function(opts)
				vim.keymap.set({ "n", "v", "i" }, "<leader>r", "<Plug>RestNvimPreview", {
					desc = "Send request",
					buffer = opts.buffer,
				})
			end,
		})
	end
}
