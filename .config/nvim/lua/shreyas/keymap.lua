vim.g.mapleader = " "
vim.g.maplocalleader = " "

local function nmap(map, fn, desc)
	vim.keymap.set("n", map, fn, { desc = desc })
end

local function xmap(map, fn, desc)
	vim.keymap.set({ "v" }, map, fn, { desc = desc })
end

vim.keymap.set("n", "j", "v:count ? 'j' : 'gj'", { expr = true, silent = true })
vim.keymap.set("n", "k", "v:count ? 'k' : 'gk'", { expr = true, silent = true })
nmap("<leader>ww", function()
	vim.o.wrap = not vim.o.wrap
end, "Toggle wrap")

xmap("J", ":m '>+1<CR>gv=gv", "Move Selection down")
xmap("K", ":m '<-2<CR>gv=gv", "Move Selection up")

nmap("U", "<C-r>", "Redo")

vim.keymap.set({ "n", "v" }, "<A-k>", "{", { desc = "Move to previous paragraph" })
vim.keymap.set({ "n", "v" }, "<A-j>", "}", { desc = "Move to next paragraph" })

nmap("<leader>p", [["+p]], "Paste from clipboard")
nmap("<leader>P", [["+P]], "Paste from clipboard before cursor")
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to clipboard" })
nmap("<leader>Y", [["+Y]], "Copy to clipboard until end of line")
nmap("<leader>e", vim.cmd.Ex, "Open Netrw")
nmap("cit", [[f>lct<]], "Change inside tag")

local function fmt_and_save()
	vim.cmd.w()
	require("conform").format({ async = true, lsp_fallback = true })
end

vim.keymap.set({ "n", "i", "v" }, "<A-s>", fmt_and_save, { desc = "Save file" })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
	pattern = "*",
})
