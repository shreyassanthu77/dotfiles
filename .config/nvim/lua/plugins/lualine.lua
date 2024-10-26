return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	opts = function()
		require("plugins.theme")
		return {
			options = {
				icons_enabled = true,
				theme = "material",
				component_separators = "|",
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = {
					function()
						local mode = require("lualine.utils.mode").get_mode()
						local recording = vim.fn.reg_recording()
						if recording == "" then
							return mode
						end
						return " " .. recording
					end,
				},
				lualine_c = { {
					"buffers",
					filetype_names = {
						oil = "Files",
					}
				} },
			},
		}
	end,
}
