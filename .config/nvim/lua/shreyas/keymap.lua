vim.g.mapleader = " "
vim.g.maplocalleader = " "

local function nmap(map, fn, desc)
	vim.keymap.set("n", map, fn, { desc = desc })
end

local function xmap(map, fn, desc)
	vim.keymap.set({ "v" }, map, fn, { desc = desc })
end

nmap("n", "nzz", "Jump to next match")
nmap("N", "Nzz", "Jump to previous match")
nmap("<C-d>", "<C-d>zz", "Scroll down half a page")
nmap("<C-u>", "<C-u>zz", "Scroll up half a page")
nmap("<C-4>", "$", "Jump to end of file")

nmap("<leader>tt", ":tabnew<CR>", "New tab")
nmap("<leader>tc", ":tabclose<CR>", "Close tab")
nmap("<leader>tn", ":tabnext<CR>", "Next tab")
nmap("<leader>tp", ":tabprevious<CR>", "Previous tab")

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
nmap("<leader>tr", ":terminal<CR>", "Open Terminal")
nmap("<leader>te", function()
	local term_bufnr = vim.fn.bufnr("term://")
	if term_bufnr == -1 then
		vim.cmd("terminal")
	else
		local term_winnr = vim.fn.bufwinnr(term_bufnr)
		if term_winnr == -1 then
			vim.cmd("buffer " .. term_bufnr)
		else
			vim.cmd(term_winnr .. "wincmd w")
		end
	end
	vim.cmd("startinsert")
end, "Toggle Terminal")

vim.keymap.set("n", "j", "v:count ? 'j' : 'gj'", { expr = true, silent = true })
vim.keymap.set("n", "k", "v:count ? 'k' : 'gk'", { expr = true, silent = true })
nmap("<leader>ww", function()
	vim.o.wrap = not vim.o.wrap
end, "Toggle wrap")

xmap("J", ":m '>+1<CR>gv=gv", "Move Selection down")
xmap("K", ":m '<-2<CR>gv=gv", "Move Selection up")

nmap("U", "<C-r>", "Redo")

vim.keymap.set({ "n", "v" }, "<A-k>", "{zz", { desc = "Move to previous paragraph" })
vim.keymap.set({ "n", "v" }, "<A-j>", "}zz", { desc = "Move to next paragraph" })

nmap("<leader>p", [["+p]], "Paste from clipboard")
nmap("<leader>P", [["+P]], "Paste from clipboard before cursor")
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to clipboard" })
nmap("<leader>Y", [["+Y]], "Copy to clipboard until end of line")
nmap("<leader>e", vim.cmd.Ex, "Open Netrw")
nmap("cit", [[f>lct<]], "Change inside tag")

-- quickfix lists
nmap("<C-l>", ":cnext<CR>", "Next quickfix")
nmap("<C-h>", ":cprevious<CR>", "Previous quickfix")

vim.keymap.set({ "n", "i", "v" }, "<A-s>", vim.cmd.w, { desc = "Save file" })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
	pattern = "*",
})
