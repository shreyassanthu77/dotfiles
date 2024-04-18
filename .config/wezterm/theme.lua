local wezterm = require("wezterm")

local function theme(config)
	config.font = wezterm.font("Geist Mono")
	config.font_size = 19
	config.line_height = 1.2

	config.initial_rows = 40
	config.enable_scroll_bar = true

	config.dpi = 96

	config.enable_tab_bar = false
	config.use_fancy_tab_bar = true
	config.tab_bar_at_bottom = true
	config.hide_tab_bar_if_only_one_tab = false

	config.window_decorations = "RESIZE"
	config.window_frame = {
		font = config.font,
		font_size = config.font_size * 0.65,
		active_titlebar_bg = "#1c2128",
		inactive_titlebar_bg = "#202020",
	}
	config.colors = {
		background = "#000000",
		tab_bar = {
			active_tab = {
				bg_color = config.window_frame.active_titlebar_bg,
				fg_color = "#d0d0d0",
				intensity = "Bold",
			},
			inactive_tab = {
				bg_color = config.window_frame.inactive_titlebar_bg,
				fg_color = "#808080",
			},
		},
	}
	config.window_padding = {
		left = 6,
		right = 0,
		top = 0,
		bottom = 8
	}
	config.window_background_opacity = 0.75
end

return theme
