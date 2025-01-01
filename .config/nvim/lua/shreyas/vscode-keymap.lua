local vscode = require("vscode")

local function nmap(keys, func, desc)
	if desc then
		desc = "LSP: " .. desc
	end

	vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
end

nmap("<leader>dp", function()
	vscode.call("editor.action.marker.prev")
end, "[D]iagnostic [P]revious")
nmap("<leader>dn", function()
	vscode.call("editor.action.marker.next")
end, "[D]iagnostic [N]ext")
nmap("<leader>dl", function()
	vscode.call("workbench.actions.view.problems")
end, "[D]iagnostic [N]ext")
