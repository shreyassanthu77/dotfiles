vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 5

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

vim.opt.swapfile = false
vim.opt.updatetime = 300
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.signcolumn = "yes"


vim.o.foldcolumn = "0"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
