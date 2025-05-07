local vscode = require("vscode")

local function nmap(keys, func, desc)
	if desc then
		desc = desc
	end

	vim.keymap.set("n", keys, func, { desc = desc })
end

local function map(mode, keys, func, desc)
	if desc then
		desc = desc
	end

	vim.keymap.set(mode, keys, func, { desc = desc })
end


map({ "n", "i" }, "<A-b>", function()
	vim.cmd.write()
end, "Save")

nmap("<leader>dp", function()
	vscode.call("editor.action.marker.prev")
end, "[D]iagnostic [P]revious")
nmap("<leader>dn", function()
	vscode.call("editor.action.marker.next")
end, "[D]iagnostic [N]ext")
nmap("<leader>dl", function()
	vscode.call("workbench.actions.view.problems")
end, "[D]iagnostic [N]ext")
