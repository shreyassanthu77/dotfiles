local zls_path = vim.fs.normalize("~/.zvm/bin/zls")

-- taken from https://github.com/LazyVim/LazyVim/blob/25abbf546d564dc484cf903804661ba12de45507/lua/lazyvim/util/init.lua#L250
local function get_pkg_path(pkg, path, opts)
	local root = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
	path = path or ""
	return root .. "/packages/" .. pkg .. "/" .. path
end


return {
	clangd = {
		-- root_dir = require("lspconfig.util").root_pattern(".clangd"),
		single_file_support = true,
		filetypes = { "c", "cpp", "objc", "objcpp", "cuda" }
	},
	-- kotlin_language_server = {
	-- 	-- init_options = {
	-- 	-- 	storagePath = require('lspconfig.util').path.join(vim.env.XDG_DATA_HOME, "nvim-data")
	-- 	},
	-- },
	gopls = {},
	pyright = {},
	jsonls = {},
	emmet_language_server = {
		filetypes = {
			"css",
			"eruby",
			"html",
			"javascript",
			"javascriptreact",
			"less",
			"css",
			"scss",
			"typescriptreact",
			"svelte",
			"vue",
			"astro",
			"templ",
		},
	},
	tailwindcss = {
		filetypes = {
			"aspnetcorerazor",
			"astro",
			"astro-markdown",
			"blade",
			"clojure",
			"django-html",
			"htmldjango",
			"edge",
			"eelixir",
			"elixir",
			"ejs",
			"erb",
			"eruby",
			"gohtml",
			"gohtmltmpl",
			"haml",
			"handlebars",
			"hbs",
			"html",
			"html-eex",
			"heex",
			"jade",
			"leaf",
			"liquid",
			"markdown",
			"mdx",
			"mustache",
			"njk",
			"nunjucks",
			"php",
			"razor",
			"slim",
			"twig",
			"css",
			"less",
			"postcss",
			"sass",
			"scss",
			"stylus",
			"sugarss",
			"javascript",
			"javascriptreact",
			"reason",
			"rescript",
			"typescript",
			"typescriptreact",
			"vue",
			"svelte",
			"templ",
		},
		init_options = {
			userLanguages = {
				templ = "html",
			},
		},
	},
	rust_analyzer = {},
	templ = {},
	dockerls = {},
	docker_compose_language_service = {},
	vtsls = {
		root_dir = function(startpath)
			local util = require("lspconfig.util")
			local p = util.root_pattern("package.json")(startpath)
			if p ~= nil and not util.path.exists(p .. "/deno.json") and not util.path.exists(p .. "/deno.jsonc") then
				return p
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
							location = get_pkg_path("svelte-language-server", "/node_modules/typescript-svelte-plugin"),
							enableForWorkspaceTypeScriptVersions = true,
						},
					}
				}
			},
			typescript = {
				updateImportsOnFileMove = { enabled = "always" },
				suggest = {
					completeFunctionCalls = true,
				},
				inlayHints = {
					enumMemberValues = { enabled = true },
					functionLikeReturnTypes = { enabled = true },
					parameterNames = { enabled = "literals" },
					parameterTypes = { enabled = true },
					propertyDeclarationTypes = { enabled = true },
					variableTypes = { enabled = false },
				},
			},
		}
	},
	denols = {
		root_dir = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc"),
	},
	html = {
		settings = {
			{ filetypes = { "html", "twig", "hbs" } },
		},
	},
	cssls = {},
	astro = {
		root_dir = require("lspconfig.util").root_pattern("astro.config.js", "astro.config.mjs"),
	},
	svelte = {
		root_dir = require("lspconfig.util").root_pattern("svelte.config.js", "svelte.config.mjs"),
	},

	prismals = {},
	lua_ls = {
		Lua = {
			workspace = { checkThirdParty = false },
			telemetry = { enable = false },
		},
	},

	ocamllsp = {
		cmd = { "ocamllsp" },
	},

	sqlls = {},
	taplo = {},

	zls = {
		cmd = { zls_path },
	},
}
