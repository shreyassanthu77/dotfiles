return {
	settings = {
		Lua = {
			codeLens = { enable = true },
			hint = { enable = true, semicolon = "Disable" },
			runtime = {
				version = "LuaJIT",
				path = {
					"lua/?.lua",
					"lua/?/init.lua",
				},
			},
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME,
				},
			},
		},
	},
}
