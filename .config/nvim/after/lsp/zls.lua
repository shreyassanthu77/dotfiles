local u = require("utils")

--- @type vim.lsp.Config
return {
	cmd = { u.home_rel(".zvm/bin/zls") },
}
