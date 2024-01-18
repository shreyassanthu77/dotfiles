vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.cmdheight = 0
vim.opt.wrap = false

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.signcolumn = "yes"

vim.opt.updatetime = 50

vim.o.foldcolumn = "0"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
