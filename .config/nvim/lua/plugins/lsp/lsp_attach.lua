local function on_attach(client, bufnr)
	local trouble = require("trouble")

	-- if client.name == "svelte" or client.name == "astro" or client.name == "ts_ls" then
	-- 	print("Adding client: " .. client.name)
	-- 	add_client(client)
	-- end

	if client.name == "svelte" then
		vim.api.nvim_create_autocmd("BufWritePost", {
			pattern = { "*.js", "*.ts" },
			group = vim.api.nvim_create_augroup("svelte_ondidchangetsorjsfile", { clear = true }),
			callback = function(ctx)
				client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
			end,
		})
	end

	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end
	local nimap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set({ "n", "i" }, keys, func, { buffer = bufnr, desc = desc })
	end

	nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")


	nmap("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
	-- nmap("g", vim.lsp.buf.definition, "[G]oto [D]efinition")
	nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
	nmap("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
	nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
	nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
	nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
	nmap("<leader>dd", function()
		trouble.toggle({
			mode = "diagnostics",
			focus = true,
			auto_close = true,
		})
	end, "[D]iagnostic [D]etails")
	nmap("<leader>dp", vim.diagnostic.goto_prev, "[D]iagnostic [P]revious")
	nmap("<leader>dn", vim.diagnostic.goto_next, "[D]iagnostic [N]ext")
	nmap("<leader>dl", vim.diagnostic.open_float, "[D]iagnostic [L]ist")

	nmap("K", vim.lsp.buf.hover, "Hover Documentation")
	nimap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

	nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")


	if client.server_capabilities.inlayHintProvider then
		nmap("<leader>hl", function()
			if vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }) then
				vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
			else
				vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			end
		end, "Toggle Inlay Hints")
	end
end

-- sone stuff to make deno goto definition work
local function virtual_text_document(params)
	local bufnr = params.buf
	local actual_path = params.match:sub(1)

	local clients = vim.lsp.get_clients({ name = "denols" })
	if #clients == 0 then
		return
	end

	local client = clients[1]
	local method = "deno/virtualTextDocument"
	local req_params = { textDocument = { uri = actual_path } }
	local response = client.request_sync(method, req_params, 2000, 0)
	if not response or type(response.result) ~= "string" then
		return
	end

	local lines = vim.split(response.result, "\n")
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_set_option_value("readonly", true, { buf = bufnr })
	vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
	vim.api.nvim_buf_set_name(bufnr, actual_path)
	vim.lsp.buf_attach_client(bufnr, client.id)

	local filetype = "typescript"
	if actual_path:sub(-3) == ".md" then
		filetype = "markdown"
	end
	vim.api.nvim_set_option_value("filetype", filetype, { buf = bufnr })
end

vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
	pattern = { "deno:/*" },
	callback = virtual_text_document,
})

return on_attach
