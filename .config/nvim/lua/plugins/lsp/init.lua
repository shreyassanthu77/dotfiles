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

			{
				'saghen/blink.cmp',
				dependencies = { 'rafamadriz/friendly-snippets' },
				version = '1.*',
			},

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
			local blink = require("blink.cmp")
			capabilities = vim.tbl_deep_extend("keep", capabilities, overrides)
			-- capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
			capabilities = blink.get_lsp_capabilities(capabilities)

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



			blink.setup({

				completion = {
					documentation = {
						auto_show = true,
						auto_show_delay_ms = 20,
					},
					menu = {
						draw = {
							columns = { { "label", "label_description", }, { "kind_icon" } }
						}
					},
				},
				keymap = {
					preset = 'enter',
					['<C-d>'] = { "scroll_documentation_down" },
					['<C-f>'] = { "scroll_documentation_up" },
					['<Tab>'] = {
						function(cmp)
							if cmp.is_ghost_text_visible() and not cmp.is_menu_visible() then
								return cmp.accept()
							end
						end,
						"select_next", "fallback" },
					['<S-Tab>'] = { "select_prev", "fallback" },
					['<A-e>'] = { "cancel" },
				},
			})

			vim.filetype.add({
				filename = {
					["docker-compose.yml"] = "yaml.docker-compose",
					["docker-compose.yaml"] = "yaml.docker-compose",
				},
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
