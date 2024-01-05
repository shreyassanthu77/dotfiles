return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	config = function()
		local harpoon = require("harpoon")

		harpoon:setup({
			settings = {
				save_on_toggle = true,
				sync_on_ui_close = true,
			},
		})

		vim.keymap.set("n", "<leader>a", function()
			harpoon:list():append()
		end, { desc = "[Harpoon] Add file" })
		vim.keymap.set("n", "<leader>hh", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "[Harpoon] Toggle menu" })

		vim.keymap.set("n", "<leader>ha", function()
			harpoon:list():select(1)
		end, { desc = "[Harpoon] goto 1" })
		vim.keymap.set("n", "<leader>hs", function()
			harpoon:list():select(2)
		end, { desc = "[Harpoon] goto 2" })
		vim.keymap.set("n", "<leader>hd", function()
			harpoon:list():select(3)
		end, { desc = "[Harpoon] goto 3" })
		vim.keymap.set("n", "<leader>hf", function()
			harpoon:list():select(4)
		end, { desc = "[Harpoon] goto 4" })
	end,
}
