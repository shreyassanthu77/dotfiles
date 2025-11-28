local u = require("utils")

vim.o.termguicolors = true -- enable true colors

vim.g.mapleader = " " -- leader key
vim.g.maplocalleader = " " -- local leader key

vim.o.laststatus = 3 -- global statusline
vim.o.cmdheight = 0 -- only show cmdline when in command mode

vim.o.number = true -- show line numbers
vim.o.relativenumber = true -- show relative line number

vim.o.splitbelow = true -- open horizontal split below
vim.o.splitright = true -- open vertical split right

vim.o.wrap = false -- don't wrap lines by default

vim.o.scrolloff = 8 -- scroll when cursor is 8 lines away from screen edge
vim.o.sidescrolloff = 5 -- scroll when cursor is 5 columns away from screen edge

vim.o.tabstop = 2 -- tab width
vim.o.shiftwidth = 0 -- use the tab width

vim.o.swapfile = false -- don't use swapfile
vim.o.backup = false -- don't create backups
vim.o.undodir = u.home_rel(".vim/undodir") -- undo files
vim.o.undofile = true -- enable undo

vim.o.hlsearch = false -- don't highlight search results
vim.o.incsearch = true -- do incremental searching
vim.o.ignorecase = true -- ignore case
vim.o.smartcase = true -- smart case

vim.o.signcolumn = "yes" -- always show signcolumns

vim.o.showtabline = 0 -- don't show tabline

vim.o.foldcolumn = "0" -- don't show fold column
vim.o.foldlevel = 99 -- don't fold by default
vim.o.foldlevelstart = 99 -- don't fold by default
vim.o.foldenable = true -- enable folding

u.autocmd_group("TextYankPost", {
	group = "copytext-highlight",
	callback = function()
		vim.hl.on_yank()
	end,
})

u.map({
	{ { "n", "i", "v" }, "<A-s>", vim.cmd.w },

	{ { "v" }, "J", ":m '>+1<CR>gv=gv" },
	{ { "v" }, "K", ":m '<-2<CR>gv=gv" },

	["U"] = "<C-r>",

	{ { "n", "v" }, "<A-k>", "{zz" },
	{ { "n", "v" }, "<A-j>", "}zz" },

	["<leader>p"] = [["+p]],
	["<leader>P"] = [["+P]],
	{ { "n", "v" }, "<leader>y", [["+y]] },
	["<leader>Y"] = [["+Y]],

	["n"] = "nzz",
	["N"] = "Nzz",
	["<C-d>"] = "<C-d>zz",
	["<C-u>"] = "<C-u>zz",

	["<C-l>"] = ":cnext<CR>",
	["<C-h>"] = ":cprevious<CR>",

	["<leader>tt"] = ":tabnew<CR>",
	["<leader>tc"] = ":tabclose<CR>",
	["<leader>tn"] = ":tabnext<CR>",
	["<leader>tp"] = ":tabprevious<CR>",

	{ "t", "<Esc><Esc>", "<C-\\><C-n>" },
	["<leader>te"] = ":terminal<CR>",

	["<leader>ww"] = ":set wrap!<CR>",
})

u.pack({
	{
		source = "jiaoshijie/undotree",
		lazy = true,
		config = function()
			local undotree = require("undotree")
			undotree.setup({})
			u.nmap("<leader>u", undotree.toggle)
		end,
	},
	{
		source = "navarasu/onedark.nvim",
		depends = {
			"xiyaowong/transparent.nvim",
			"marko-cerovac/material.nvim",
		},
		config = function()
			local onedark = require("onedark")
			onedark.setup({
				style = "darker",
			})
			onedark.load()

			local material = require("material")
			vim.g.material_style = "deep ocean"
			material.setup({
				lualine_style = "stealth",
			})

			require("transparent").setup({
				extra_groups = {
					"AvanteSidebarNormal",
					"AvanteSidebarWinSeparator",
					"AvanteSidebarWinHorizontalSeparator",
				},
			})
			vim.cmd.TransparentEnable()
		end,
	},
	{
		source = "nvim-lualine/lualine.nvim",
		depends = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			options = {
				icons_enabled = true,
				theme = "material",
				component_separators = "|",
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = {
					function()
						local mode = require("lualine.utils.mode").get_mode()
						local recording = vim.fn.reg_recording()
						if recording == "" then
							return mode
						end
						return " " .. recording
					end,
				},
				lualine_b = { "branch", "tabs" },
				lualine_c = { "buffers" },
			},
		},
	},
	{
		source = "stevearc/oil.nvim",
		depends = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local oil = require("oil")
			oil.setup({
				skip_confirm_for_simple_edits = false,
				view_options = {
					show_hidden = true,
				},
				columns = {
					"icon",
					"size",
				},
			})

			u.nvmap("<leader>e", oil.open)
			u.autocmd("FileType", {
				pattern = "oil",
				callback = function(opts)
					u.nvimmap("<A-s>", function()
						oil.save({
							confirm = false,
						})
					end, { buffer = opts.buf })
				end,
			})
		end,
	},
	{ source = "numToStr/Comment.nvim", lazy = true },
	{ source = "cohama/lexima.vim", lazy = true },
	{ source = "echasnovski/mini.surround", lazy = true },
	{
		source = "lukas-reineke/indent-blankline.nvim",
		lazy = true,
		main = "ibl",
		opts = {
			enabled = true,
			indent = {
				char = "┊",
			},
			scope = {
				show_start = false,
				show_end = false,
			},
		},
	},
	{
		source = "lewis6991/gitsigns.nvim",
		lazy = true,
		opts = {
			current_line_blame = true,
		},
	},
	{
		source = "kevinhwang91/nvim-ufo",
		depends = { "kevinhwang91/promise-async" },
		lazy = true,
		opts = {
			---@diagnostic disable-next-line: unused-local
			provider_selector = function(bufnr, filetype, buftype)
				return { "lsp", "indent" }
			end,
		},
	},
	-- function()
	-- 	local download_done = true
	--
	-- 	local function pre_install()
	-- 		download_done = false
	-- 		-- This is a hack to make fff.nvim work with mini.deps
	-- 		vim.g.fff = { lazy_sync = true }
	-- 	end
	--
	-- 	local function on_download_done(ok, err)
	-- 		if not ok then
	-- 			vim.notify("fff.nvim build failed: " .. err, vim.log.levels.ERROR)
	-- 		end
	-- 		vim.g.fff = nil
	-- 		download_done = true
	-- 	end
	--
	-- 	local function post_install()
	-- 		-- We defer to ensure the plugin module is available in the path
	-- 		vim.defer_fn(function()
	-- 			require("fff.download").download_or_build_binary(on_download_done)
	-- 		end, 100)
	-- 	end
	--
	-- 	local function wait_for_download()
	-- 		if not download_done then
	-- 			vim.wait(100, function()
	-- 				return download_done
	-- 			end, 200)
	-- 		end
	-- 	end
	--
	-- 	--- @type PluginSpec
	-- 	return {
	-- 		source = "dmtrKovalenko/fff.nvim",
	-- 		hooks = {
	-- 			pre_install = pre_install,
	-- 			post_install = post_install,
	-- 			pre_checkout = pre_install,
	-- 			post_checkout = post_install,
	-- 		},
	-- 		config = function()
	-- 			wait_for_download()
	-- 			local fff = require("fff")
	-- 			fff.setup({
	-- 				prompt = "> ",
	-- 				hl = {
	-- 					border = "Comment",
	-- 				},
	-- 				debug = {
	-- 					enabled = false,
	-- 					show_scores = false,
	-- 				},
	-- 				logging = {
	-- 					enabled = false,
	-- 				},
	-- 			})
	--
	-- 			u.autocmd("FileType", {
	-- 				pattern = "fff_input",
	-- 				callback = function(event)
	-- 					u.nvmap("<Esc>", function()
	-- 						require("fff.picker_ui").close()
	-- 					end, { buffer = event.buf, silent = true })
	-- 				end,
	-- 			})
	--
	-- 			u.nmap("<leader><space>", require("fff").find_files)
	-- 		end,
	-- 	}
	-- end,
	{
		source = "nvim-telescope/telescope.nvim",
		depends = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
		},
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				defaults = {
					winblend = vim.g.neovide and 80 or 0,
				},
				pickers = {
					find_files = {
						hidden = true,
					},
					live_grep = {
						hidden = true,
					},
					git_files = {
						hidden = true,
						show_untracked = true,
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})

			telescope.load_extension("ui-select")

			local builtin = require("telescope.builtin")

			u.map({
				["<leader><space>"] = builtin.find_files,
				["<leader>fg"] = builtin.git_files,
				["<leader>ff"] = builtin.buffers,
				["<leader>/"] = builtin.current_buffer_fuzzy_find,
				["<leader>fl"] = builtin.live_grep,
			})
		end,
	},
	{
		source = "nvim-treesitter/nvim-treesitter",
		main = "nvim-treesitter.configs",
		hooks = {
			post_checkout = function()
				vim.cmd("TSUpdate")
			end,
		},
		opts = {
			ensure_installed = {
				"lua",
				"typescript",
				"javascript",
				"tsx",
				"css",
				"html",
				"json",
				"yaml",
				"zig",
				"python",
				"astro",
				"svelte",
				"dart",
				"go",
				"templ",
				"http",
				"ocaml",
				"vimdoc",
			},
			auto_install = false,
			highlight = { enable = true },
			indent = { enable = true },
		},
	},
	{ source = "j-hui/fidget.nvim", opts = {} },
	{
		source = "neovim/nvim-lspconfig",
		depends = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"saghen/blink.cmp",
		},
		opts = {
			--- @type table<string | integer, false | string>
			servers = {
				"clangd",
				"gopls",
				"pyright",
				"jsonls",
				"emmet_language_server",
				"tailwindcss",
				"rust_analyzer",
				"templ",
				"dockerls",
				"docker_compose_language_service",
				"vtsls",
				"denols",
				"html",
				"cssls",
				"astro",
				"svelte",
				"prismals",
				"lua_ls",
				"sqlls",
				zls = false,
			},
			--- @type string[]
			tools = {
				"prettierd",
				"stylua",
				"taplo",
			},
		},
		config = function(opts)
			u.autocmd_group("LspAttach", {
				group = "lspattach",
				callback = function(event)
					local telescope = require("telescope.builtin")
					u.map({
						["K"] = vim.lsp.buf.hover,
						{ { "n", "i" }, "<C-k>", vim.lsp.buf.signature_help },
						["<leader>ca"] = vim.lsp.buf.code_action,
						["<leader>rn"] = vim.lsp.buf.rename,
						["gd"] = telescope.lsp_definitions,
						["<leader>dp"] = function()
							vim.diagnostic.jump({ count = -1 })
						end,
						["<leader>dn"] = function()
							vim.diagnostic.jump({ count = 1 })
						end,
						["<leader>dl"] = function()
							vim.diagnostic.open_float()
						end,
						["<leader>dd"] = telescope.diagnostics,
					}, { buffer = event.buf })
				end,
			})

			vim.diagnostic.config({
				severity_sort = true,
				virtual_text = {},
			})

			local overrides = {
				workspace = {
					didChangeWatchedFiles = {
						dynamicRegistration = true,
					},
				},
				textDocument = {
					foldingRange = {
						dynamicRegistration = false,
					},
				},
			}

			local blink = require("blink.cmp")
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, overrides)
			capabilities = blink.get_lsp_capabilities(capabilities)

			--- @type string[]
			local ensure_installed = {}
			for i = 1, #opts.tools do
				table.insert(ensure_installed, opts.tools[i])
			end

			for name_or_idx, name_or_ensure in pairs(opts.servers) do
				if name_or_ensure ~= false then
					local server_name = type(name_or_ensure) == "string" and name_or_ensure
						or type(name_or_idx) == "string" and name_or_idx
						or nil
					if server_name ~= nil then
						table.insert(ensure_installed, server_name)
					end
				end
			end

			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = {}, -- handled by mason-tool-installer
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			for name_or_idx, name_or_ensure in pairs(opts.servers) do
				local server_name = type(name_or_idx) == "string" and name_or_idx
					or type(name_or_ensure) == "string" and name_or_ensure
					or nil

				if not server_name then
					return
				end

				vim.lsp.config[server_name] = {
					capabilities = capabilities,
				}
				vim.lsp.enable(server_name)
			end
		end,
	},
	{
		source = "saghen/blink.cmp",
		depends = { "rafamadriz/friendly-snippets" },
		checkout = "v1.8.0",
		opts = {
			sources = {
				default = { "snippets", "lsp", "path", "buffer" },
			},
			signature = { enabled = true },
			completion = {
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 20,
				},
				menu = {
					draw = {
						columns = { { "label", "label_description" }, { "kind_icon" } },
					},
				},
			},
			keymap = {
				preset = "enter",
				["<C-d>"] = { "scroll_documentation_down" },
				["<C-f>"] = { "scroll_documentation_up" },
				["<Tab>"] = { "select_next", "fallback" },
				["<S-Tab>"] = { "select_prev", "fallback" },
				["<A-e>"] = { "cancel" },
			},
		},
	},
	{ source = "folke/neoconf.nvim", lazy = true },
	{
		source = "stevearc/conform.nvim",
		lazy = true,
		opts = {
			formatters_by_ft = {
				javascript = { "prettierd" },
				javascriptreact = { "prettierd" },
				typescript = { "prettierd" },
				typescriptreact = { "prettierd" },
				json = { "deno_fmt", "prettierd" },
				jsonc = { "deno_fmt", "prettierd" },
				html = { "prettierd" },
				css = { "prettierd" },
				astro = { "prettierd" },
				svelte = {},
				lua = { "stylua" },
				python = { "black" },
				ocaml = { "ocamlformat" },
				markdown = { "mdformat" },
				templ = { "templ" },
			},
			format_on_save = {
				lsp_format = "fallback",
				stop_after_first = true,
				timeout = 500,
			},
		},
	},
	{
		source = "supermaven-inc/supermaven-nvim",
		lazy = true,
		opts = {
			log_level = "off",
			disable_keymaps = false,
			keymaps = {
				accept_suggestion = "<A-a>",
				accept_word = "<A-w>",
				clear_suggestion = "<A-d>",
			},
		},
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

---@diagnostic disable-next-line: duplicate-set-field
vim.ui.input = function(opts, on_confirm)
	local prompt = opts.prompt or "Input: "
	local default = opts.default or ""

	local width = math.max(vim.fn.strdisplaywidth(prompt) * 2, vim.fn.strdisplaywidth(default) * 2)
	local buf = vim.api.nvim_create_buf(false, true)
	local float = vim.api.nvim_open_win(buf, true, {
		title = prompt,
		focusable = true,
		width = width,
		relative = "cursor",
		height = 1,
		row = 0,
		col = 0,
		style = "minimal",
		border = "rounded",
	})
	vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, { default })
	vim.cmd.startinsert()
	vim.api.nvim_win_set_cursor(float, { 1, vim.fn.strdisplaywidth(default) })

	local function on_close()
		vim.cmd.stopinsert()
		vim.api.nvim_win_close(float, true)
		on_confirm(nil)
	end

	local function on_submit()
		vim.cmd.stopinsert()
		local input = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
		vim.api.nvim_win_close(float, true)
		on_confirm(input)
	end

	u.map({
		["<Esc>"] = on_close,
		["q"] = on_close,
		{ { "n", "i", "v" }, "<CR>", on_submit },
	}, { buffer = buf })
end
