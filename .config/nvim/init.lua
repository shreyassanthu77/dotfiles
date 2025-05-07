require("shreyas.settings")
require("shreyas.keymap")

local lazy = require("shreyas.lazy")
if vim.g.vscode then
	require("shreyas.vscode-keymap")
	-- lazy.setup("vscode-plugins")
else
	lazy.setup("plugins")
end
