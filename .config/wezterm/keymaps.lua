local wezterm = require("wezterm")
local act = wezterm.action

local function lmap(key, action)
	return {
		key = key,
		mods = "LEADER",
		action = action,
	}
end

local function lmmap(key, mods, action)
	return {
		key = key,
		mods = "LEADER|" .. mods,
		action = action,
	}
end

local function mmap(key, mods, action)
	return {
		key = key,
		mods = mods,
		action = action,
	}
end

local leader_key = "a"
local key_maps = {
	lmmap(leader_key, "CTRL", wezterm.action.SendKey({ key = leader_key, mods = "CTRL" })),

	mmap("n", "CTRL|ALT", act.SpawnTab("CurrentPaneDomain")),

	mmap("n", "ALT", act.ActivateTab(0)),
	mmap("i", "ALT", act.ActivateTab(1)),
	mmap("o", "ALT", act.ActivateTab(2)),
	mmap(";", "ALT", act.ActivateTab(3)),

	lmap("w", act.CloseCurrentTab({ confirm = false })),
	lmap("c", act.ToggleFullScreen),
	lmap("t", act.ShowTabNavigator),

	lmap("j", act.ActivatePaneDirection("Down")),
	lmap("k", act.ActivatePaneDirection("Up")),
	lmap("h", act.ActivatePaneDirection("Left")),
	lmap("l", act.ActivatePaneDirection("Right")),
	lmmap("j", "SHIFT", act.SplitPane({ direction = "Down" })),
	lmmap("k", "SHIFT", act.SplitPane({ direction = "Up" })),
	lmmap("h", "SHIFT", act.SplitPane({ direction = "Left" })),
	lmmap("l", "SHIFT", act.SplitPane({ direction = "Right" })),
	lmmap("j", "CTRL", act.AdjustPaneSize({ "Down", 2 })),
	lmmap("k", "CTRL", act.AdjustPaneSize({ "Up", 2 })),
	lmmap("h", "CTRL", act.AdjustPaneSize({ "Left", 2 })),
	lmmap("l", "CTRL", act.AdjustPaneSize({ "Right", 2 })),

	lmap("s", act.SendString("cd `find ~/code | fzf`\n")),
}

local function map_keys(config)
	config.leader = { key = leader_key, mods = "CTRL" }
	config.keys = key_maps
	config.window_close_confirmation = "NeverPrompt"
end

return map_keys
