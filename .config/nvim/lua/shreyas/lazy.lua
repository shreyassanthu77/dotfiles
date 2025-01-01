local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local M = {}
--- Setup Lazy
---@param spec LazySpec
M.setup = function(spec)
	require("lazy").setup(spec, {
		change_detection = {
			notify = false,
		},
	})
end

return M
