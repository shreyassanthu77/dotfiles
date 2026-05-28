local u = require("utils")

--- @type vim.lsp.Config
return {
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"toml",
		"json",
		"jsonc",
		"json5",
		"yaml",
		"html",
		"vue",
		"svelte",
		"handlebars",
		"css",
		"scss",
		"less",
		"graphql",
		"markdown",
	},
	root_dir = u.lsp_root_dir({
		"oxfmt.config.ts",
		"oxfmt.config.js",
		"oxfmt.config.mjs",
		"oxfmt.config.cjs",
		".oxfmtrc.json",
		".oxfmtrc.jsonc",
		"package.json",
	}),
}
