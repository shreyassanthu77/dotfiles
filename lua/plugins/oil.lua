return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local oil = require("oil")
		oil.setup({
			skip_confirm_for_simple_edits = false,
			view_options = {
				show_hidden = true,
			},
		})
		vim.keymap.set({ "n", "v" }, "<leader>e", oil.open, {
			desc = "Open file explorer",
		})
		vim.api.nvim_create_autocmd({ "BufEnter" }, {
			callback = function(opts)
				local buf = opts.buf
				local type = vim.bo[buf].ft

				if type == "oil" then
					vim.keymap.set({ "n", "v", "i" }, "<A-s>", function()
						oil.save({
							confirm = false,
						})
					end, {
						desc = "Save changes",
						buffer = buf,
					})
				end
			end,
		})
	end,
}
