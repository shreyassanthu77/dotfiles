local u = require("utils")
--- @type vim.lsp.Config
return {
	root_dir = u.lsp_root_dir({ "svelte.config.js", "svelte.config.mjs" }),
}
