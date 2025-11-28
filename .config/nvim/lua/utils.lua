local M = {}

--- map a key to a function in normal mode
--- @param map string key to map
--- @param fn string|function function to map to
--- @param opts? vim.keymap.set.Opts options for the keymap
M.nmap = function(map, fn, opts)
	vim.keymap.set("n", map, fn, opts)
end

--- map a key to a function in visual mode
--- @param map string key to map
--- @param fn string|function function to map to
--- @param opts? vim.keymap.set.Opts options for the keymap
M.vmap = function(map, fn, opts)
	vim.keymap.set("v", map, fn, opts)
end

--- map a key to a function in normal and visual mode
--- @param map string key to map
--- @param fn string|function function to map to
--- @param opts? vim.keymap.set.Opts options for the keymap
M.nvmap = function(map, fn, opts)
	vim.keymap.set({ "n", "v" }, map, fn, opts)
end

--- map a key to a function in normal, insert and visual mode
--- @param map string key to map
--- @param fn string|function function to map to
--- @param opts? vim.keymap.set.Opts options for the keymap
M.nvimmap = function(map, fn, opts)
	vim.keymap.set({ "n", "i", "v" }, map, fn, opts)
end

--- @alias Mapping {
---		[string]: string|function,
---		[number]: {
---				[1]: string[]|string,
---				[2]: string,
---				[3]: string|function,
---				[4]?: vim.keymap.set.Opts,
---		},
--- }

--- @param maps Mapping
--- @param opts? vim.keymap.set.Opts default options for all mappings
M.map = function(maps, opts)
	for keys, fn in pairs(maps) do
		if type(keys) == "string" then
			---@diagnostic disable-next-line: param-type-mismatch
			vim.keymap.set("n", keys, fn, opts)
		elseif type(keys) == "number" then
			local merged_opts = vim.tbl_deep_extend("force", opts or {}, fn[4] or {})
			vim.keymap.set(fn[1], fn[2], fn[3], merged_opts)
		end
	end
end

M.autocmd = vim.api.nvim_create_autocmd

--- @class (exact) AutocmdGroupOpts: vim.api.keyset.create_autocmd
--- @field group string
--- @field clear? boolean

--- @param event string
--- @param opts AutocmdGroupOpts
M.autocmd_group = function(event, opts)
	local group_name = opts.group .. event .. "utils.autocmd_group"
	local clear = opts.clear
	if not clear then
		clear = true
	end
	---@diagnostic disable-next-line: assign-type-mismatch
	opts.group = vim.api.nvim_create_augroup(group_name, { clear = clear })
	vim.api.nvim_create_autocmd(event, opts)
end

--- get a path relative to the home directory
--- @param sub_path string path relative to home directory
M.home_rel = function(sub_path)
	return os.getenv("HOME") .. "/" .. sub_path
end

local path_package = vim.fn.stdpath("data") .. "/site/"
--- @param sub_path string path relative to deps directory
--- @param start? boolean
local function deps_rel(sub_path, start)
	local path = path_package .. "pack/deps/"
	if start then
		path = path .. "start/"
	else
		path = path .. "opt/"
	end
	return vim.fs.joinpath(path, sub_path)
end

--- taken from lazy nvim source
--- @param name string
--- @return string
local function normalize_module_name(name)
	local res = name:lower():gsub("^n?vim%-", ""):gsub("%.n?vim$", ""):gsub("[%.%-]lua", ""):gsub("[^a-z]+", "")
	return res
end

--- @param source string
--- @return string main
local function get_plugin_main(source)
	local name = source
	if name:sub(-4) == ".git" then
		name = name:sub(1, -5)
	end
	if name:sub(-1) == "/" then
		name = name:sub(1, -2)
	end
	local last_slash = name:reverse():find("/", 1, true)
	if last_slash then
		name = name:sub(#name - last_slash + 2)
	end

	if name ~= "mini.nvim" and name:match("^mini%..*$") then
		return name
	end

	local lua_path = deps_rel(name .. "/lua")

	--- @type string[]
	local modules = {}
	for file_name, type in vim.fs.dir(lua_path) do
		--- @type string
		local module_name
		if type == "file" and file_name:sub(-4) == ".lua" then
			module_name = file_name:sub(1, -5)
		elseif type == "directory" then
			local init_file = vim.fs.joinpath(lua_path, file_name, "/init.lua")
			if vim.loop.fs_stat(init_file) then
				module_name = file_name
			end
		end

		if module_name then
			table.insert(modules, module_name)
		end
	end

	local normalized_name = normalize_module_name(name)
	for _, module_name in ipairs(modules) do
		if normalize_module_name(module_name) == normalized_name then
			return module_name
		end
	end

	if #modules == 1 then
		return modules[1]
	end

	return normalized_name
end

--- @class PluginHooks
--- @field pre_install? function
--- @field post_install? function
--- @field pre_checkout? function
--- @field post_checkout? function
---
--- @class (exact) PluginSpec
--- @field source string the url of the plugin
--- @field checkout? string the branch/tag/commit to checkout
--- @field depends? string[] the names of the plugins this plugin depends on
--- @field hooks? PluginHooks hooks to run before/after installing the plugin
--- @field lazy? boolean whether to lazy load the plugin (default: false)
--- @field opts? (table|false) options to pass to the setup function (set to false to disable autoloading)
--- @field main? string the name of the main module of the plugin (default: uses a heuristic to find the main module)
--- @field config? function a custom setup function to run. the opts are passed to the setup function

--- @alias PluginSpecFn fun():PluginSpec
--- @param specs (PluginSpec|PluginSpecFn)[]
M.pack = function(specs)
	local mini_path = deps_rel("mini.deps", true)
	if not vim.loop.fs_stat(mini_path) then
		vim.cmd('echo "Installing `mini.deps`" | redraw')
		local clone_cmd = {
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/nvim-mini/mini.deps",
			mini_path,
		}
		vim.fn.system(clone_cmd)
		vim.cmd("packadd mini.deps | helptags ALL")
		vim.cmd('echo "Installed `mini.deps`" | redraw')
	end

	local deps = require("mini.deps")
	deps.setup({ path = { package = path_package } })

	--- @param spec PluginSpec
	local function load_plugin(spec)
		local lazy = spec.lazy or false

		local schedule_fn = lazy and deps.later or deps.now
		schedule_fn(function()
			deps.add(spec)
			if spec.config then
				spec.config(spec.opts)
			else
				if spec.opts == false then
					return
				end
				local main = spec.main or get_plugin_main(spec.source)
				local ok, mod = pcall(require, main)
				if not ok then
					return
				end
				if mod.setup then
					mod.setup(spec.opts)
				else
					print("No setup function found for " .. main)
				end
			end
		end)
	end

	for _, spec in ipairs(specs) do
		--- @type PluginSpec
		---@diagnostic disable-next-line: assign-type-mismatch
		local spec_resolved = type(spec) == "function" and spec() or spec
		load_plugin(spec_resolved)
	end
end

--- Gets a path to a package in the Mason registry.
--- taken from https://github.com/LazyVim/LazyVim/blob/25abbf546d564dc484cf903804661ba12de45507/lua/lazyvim/util/init.lua#L250
---@param pkg string
---@param path? string
---@return string
M.get_mason_package_path = function(pkg, path)
	local root = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
	path = path or ""
	return root .. "/packages/" .. pkg .. "/" .. path
end

--- @param marker string|(string|fun(name: string, path: string):boolean|string[])[]|fun(name: string, path: string):boolean
M.lsp_root_dir = function(marker)
	--- @param buf integer
	--- @param on_dir fun(root_dir: string)
	return function(buf, on_dir)
		local dir = vim.fs.root(buf, marker)
		if dir ~= nil then
			on_dir(dir)
		end
	end
end

return M
