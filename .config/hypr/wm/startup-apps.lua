return function(apps)
    -- Like exec-once: reloading the config does not spawn duplicate processes.
    hl.on("hyprland.start", function()
        hl.exec_cmd("hypridle")
        hl.exec_cmd("~/.config/hypr/scripts/external-monitor")
        hl.exec_cmd("hyprpaper")
        hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
        hl.dispatch(hl.dsp.exec_cmd(apps.terminal, { workspace = "1 silent", no_anim = true }))
        hl.dispatch(hl.dsp.exec_cmd(apps.browser, { workspace = "2 silent", no_anim = true, tile = true }))
    end)
end
