local zls_path = vim.fs.normalize("~/.local/bin/zls")

return {
	clangd = {
		-- root_dir = require("lspconfig.util").root_pattern(".clangd"),
		single_file_support = true,
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
	tsserver = {
		root_dir = require("lspconfig.util").root_pattern("package.json"),
		single_file_support = false,
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

	ocamllsp = {},

	sqlls = {},

	zls = {
		cmd = { zls_path }
	},
}
