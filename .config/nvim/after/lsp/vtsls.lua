local u = require("utils")

--- @type vim.lsp.Config
return {
	root_dir = function(buf, on_dir)
		local deno_root = vim.fs.root(buf, { "deno.json", "deno.jsonc" })
		if deno_root ~= nil then
			return
		end
		local node_root = vim.fs.root(buf, { "package.json", "tsconfig.json", "jsconfig.json" })
		if node_root ~= nil then
			on_dir(node_root)
		end
	end,
	single_file_support = false,
	settings = {
		complete_function_calls = true,
		vtsls = {
			autoUserWorkspaceTsdk = true,
			tsserver = {
				globalPlugins = {
					{
						name = "typescript-svelte-plugin",
						location = u.get_mason_package_path(
							"svelte-language-server",
							"/node_modules/typescript-svelte-plugin"
						),
						enableForWorkspaceTypeScriptVersions = true,
					},
					{
						name = "@astrojs/ts-plugin",
						location = u.get_mason_package_path(
							"astro-language-server",
							"/node_modules/@astrojs/ts-plugin"
						),
						enableForWorkspaceTypeScriptVersions = true,
					},
				},
			},
		},
		typescript = {
			updateImportsOnFileMove = { enabled = "always" },
			suggest = {
				completeFunctionCalls = true,
			},
		},
	},
}
