vim.o.termguicolors = true
return {
	{
		"navarasu/onedark.nvim",
		dependencies = {
			"xiyaowong/transparent.nvim",
		},
		lazy = false,
		priority = 1000,
		opts = {
			style = "darker",
		},
		config = function(conf)
			local onedark = require("onedark")
			onedark.setup(conf.opts)
			onedark.load()
			vim.cmd.TransparentEnable()
		end,
	},
}
