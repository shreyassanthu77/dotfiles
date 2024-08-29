local function on_attach(client, bufnr)
	local trouble = require("trouble")

	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

	nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
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
	nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

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

return on_attach
