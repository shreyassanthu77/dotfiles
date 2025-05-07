return {
	"sindrets/diffview.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons"
	},
	config = function()
		local diffview = require("diffview")
		diffview.setup({
			view = {
				default = {
					layout = "diff2_vertical",
				}
			},
			keymaps = {
				file_panel = {
					{
						"n", "cc",
						function()
							vim.ui.input({ prompt = "Commit message: " }, function(msg)
								if not msg then return end
								local results = vim.system({ "git", "commit", "-m", msg }, { text = true }):wait()

								if results.code ~= 0 then
									vim.notify(
										"Commit failed with the message: \n"
										.. vim.trim(results.stdout .. "\n" .. results.stderr),
										vim.log.levels.ERROR,
										{ title = "Commit" }
									)
								else
									vim.notify(results.stdout, vim.log.levels.INFO, { title = "Commit" })
								end
							end)
						end,
						{ desc = "Commit staged changes" },
					},
					{
						"n", "ca",
						"<Cmd>sp <bar> wincmd J <bar> term git commit --amend --no-edit<CR>",
						{ desc = "Amend the last commit" },
					},
				},
				view = {
					{ { "n", "v", "x" }, "<leader>dg", function() vim.cmd.diffget() end, { desc = "get chages from the other diff buffer" } },
					{ { "n", "v", "x" }, "<leader>dp", function() vim.cmd.diffput() end, { desc = "put changes into the other diff buffer" } },
				}
			}
		})

		vim.keymap.set("n", "<leader>dv", function()
			diffview.open({})
		end, { desc = "Open diffview" })
	end,
}
