local zls_path = vim.fs.normalize("~/.zvm/bin/zls")

return {
	clangd = {
		-- root_dir = require("lspconfig.util").root_pattern(".clangd"),
		single_file_support = true,
		filetypes = { "c", "cpp", "objc", "objcpp", "cuda" }
	},
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
	ts_ls = {
		root_dir = function(startpath)
			local util = require("lspconfig.util")
			local p = util.root_pattern("package.json")(startpath)
			if p ~= nil and not util.path.exists(p .. "/deno.json") then
				return p
			end
		end,
		single_file_support = false,
		settings = {
			typescript = {
				inlayHints = {
					includeInlayParameterNameHints = 'all',
					includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayVariableTypeHintsWhenTypeMatchesName = false,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayEnumMemberValueHints = true,
				}
			},
		},
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
	-- dartls = {},

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
