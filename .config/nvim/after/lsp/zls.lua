local u = require("utils")

--- @type vim.lsp.Config
return {
	cmd = { u.home_rel(".zvm/bin/zls") },
	settings = {
		zls = {
			semantic_tokens = "none",
		},
	},
}
