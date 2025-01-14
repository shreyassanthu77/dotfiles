local formatter = require("plugins/lsp/format")
local flutter = require("plugins/lsp/flutter")
local debugger = require("plugins/lsp/debugger")
local on_attach = require("plugins/lsp/lsp_attach")

return {
	"stevearc/conform.nvim",
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", config = true },
			"williamboman/mason-lspconfig.nvim",

			{ "j-hui/fidget.nvim",       opts = {} },

			"folke/neodev.nvim",
			"folke/trouble.nvim",

			-- Cmp Stuff
			"hrsh7th/nvim-cmp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",

			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-buffer",
			{
				"jdrupal-dev/css-vars.nvim",
				opts = {
					cmp_filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "svelte" },
				},
			},

			"rafamadriz/friendly-snippets",
		},
		config = function()
			require("neodev").setup()

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local overrides = {
				workspace = {
					didChangeWatchedFiles = {
						dynamicRegistration = true,
					},
				},
				textDocument = {
					foldingRange = {
						dynamicRegistration = false,
						lineFoldingOnly = true,
					},
				}
			}
			capabilities = vim.tbl_deep_extend("keep", capabilities, overrides)
			-- capabilities.textDocument.foldingRange = {
			-- 	dynamicRegistration = false,
			-- 	lineFoldingOnly = true,
			-- }
			capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

			local mason_lspconfig = require("mason-lspconfig")
			local servers = require("plugins/lsp/servers")

			local ensure_installed = {}
			local local_servers = {}
			for server_name, server in pairs(servers) do
				if server.cmd == nil then
					table.insert(ensure_installed, server_name)
				else
					table.insert(local_servers, server_name)
				end
			end
			mason_lspconfig.setup({
				ensure_installed = ensure_installed,
			})

			local function setup_server(server_name)
				local setup_opts = vim.tbl_extend("force", {
					capabilities = capabilities,
					on_attach = on_attach,
				}, servers[server_name])
				require("lspconfig")[server_name].setup(setup_opts)
			end

			mason_lspconfig.setup_handlers({
				setup_server
			})

			for _, server_name in ipairs(local_servers) do
				setup_server(server_name)
			end



			local cmp = require("cmp")
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load()
			luasnip.config.setup({})

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete({}),
					["<A-e>"] = cmp.mapping.close(),
					["<CR>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = {
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
					{ name = "buffer" },
					{ name = "css_vars" },
				},
				completion = {
					autocomplete = {
						"TextChanged",
					},
				},
			})


			vim.filetype.add({
				extension = {
					templ = "templ",
					pcss = "css",
					pest = "pest",
					ml = "ocaml",
				},
			})
		end,
	},
	formatter,
	flutter,
	debugger,
}
