-- Shared keybindings; per-app commands live in hyprland.lua.
return function(apps)
    local main_mod = "SUPER"
    local function bind(key, action, flags)
        hl.bind(main_mod .. " + " .. key, action, flags)
    end

    -- Keep zoom state in Lua and use the actual current factor for all controls.
    -- No shell processes or stale /tmp state when mixing keyboard and wheel zoom.
    local saved_zoom = 2
    local function set_zoom(factor)
        factor = math.max(1, factor)
        if factor > 1 then saved_zoom = factor end
        hl.config({ cursor = { zoom_factor = factor } })
    end
    bind("A", function()
        local current = hl.get_config("cursor.zoom_factor")
        if current > 1 then
            saved_zoom = current
            set_zoom(1)
        else
            set_zoom(saved_zoom)
        end
    end)
    bind("equal", function() set_zoom(hl.get_config("cursor.zoom_factor") + 0.2) end)
    bind("minus", function() set_zoom(hl.get_config("cursor.zoom_factor") - 0.2) end)
    bind("CTRL + mouse_down", function() set_zoom(hl.get_config("cursor.zoom_factor") * 1.1) end)
    bind("CTRL + mouse_up", function() set_zoom(hl.get_config("cursor.zoom_factor") * 0.9) end)

    -- Apps.
    bind("T", hl.dsp.exec_cmd(apps.terminal))
    bind("B", hl.dsp.exec_cmd(apps.browser))
    bind("CTRL + B", hl.dsp.exec_cmd("remote " .. apps.browser))
    bind("Q", hl.dsp.window.close())
    bind("E", hl.dsp.exec_cmd(apps.file_manager))
    bind("F", hl.dsp.window.float({ action = "toggle" }))
    bind("slash", hl.dsp.exec_cmd(apps.menu))
    bind("C", hl.dsp.exec_cmd(apps.settings, { float = true }))
    bind("SHIFT + C", hl.dsp.exec_cmd("hyprpicker | wl-copy"))
    local screenshot = 'grim -g "$(slurp)" - | wl-copy'
    hl.bind("Print", hl.dsp.exec_cmd(screenshot))
    bind("CTRL + S", hl.dsp.exec_cmd(screenshot))

    -- Focus and swap windows with the Vim navigation keys.
    for key, direction in pairs({ h = "left", l = "right", k = "up", j = "down" }) do
        bind(key, hl.dsp.focus({ direction = direction }))
        bind("SHIFT + " .. key, hl.dsp.window.swap({ direction = direction }))
    end

    -- Preserve the custom workspace keys and add the missing CTRL+5 counterpart.
    local workspace_keys = {
        { "n", 1 }, { "i", 2 }, { "o", 3 }, { "semicolon", 4 },
        { "apostrophe", 5 }, { "5", 5 }, { "6", 6 }, { "7", 7 },
        { "8", 8 }, { "9", 9 }, { "0", 10 },
    }
    for _, entry in ipairs(workspace_keys) do
        bind(entry[1], hl.dsp.focus({ workspace = entry[2] }))
        bind("CTRL + " .. entry[1], hl.dsp.window.move({ workspace = entry[2], follow = true }))
    end
    bind("S", hl.dsp.workspace.toggle_special("magic"))
    bind("SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = true }))

    -- Mouse drag/resize.
    bind("mouse:272", hl.dsp.window.drag(), { mouse = true })
    bind("mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- Laptop/media keys (same repeat behavior and 150% volume cap as before).
    hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
    hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
    hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
end
