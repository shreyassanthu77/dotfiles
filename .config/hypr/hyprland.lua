-- Hyprland 0.57+ Lua config. The old .conf files are kept for reference.
local apps = {
    terminal = "kitty",
    file_manager = "nautilus",
    settings = "XDG_CURRENT_DESKTOP=GNOME gnome-control-center",
    browser = "zen-browser",
    menu = "rofi -show combi",
}

-- Make user scripts (e.g. remote) and mise shims visible to keybinds and rofi.
hl.env("PATH", os.getenv("HOME") .. "/.local/share/mise/shims:" .. os.getenv("HOME") .. "/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin")

require("wm.monitors-and-workspaces")
require("wm.settings")
require("wm.binds")(apps)
require("wm.startup-apps")(apps)
