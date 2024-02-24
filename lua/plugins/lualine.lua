return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			icons_enabled = true,
			theme = "onedark",
			component_separators = "|",
			section_separators = { left = "", right = "" },
		},
		sections = {
			lualine_c = { "buffers" },
		},
	},
}
