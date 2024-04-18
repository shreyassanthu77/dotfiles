local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.check_for_updates = false
config.show_update_window = false
config.enable_wayland = false
require("theme")(config)
require("keymaps")(config)

return config
