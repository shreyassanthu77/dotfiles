import { theme } from "./theme";

App.applyCss(`
	.power-button:focus {
			border: 3px solid ${theme.on_secondary_color};
	}
`);

export function PowerOptions() {
  function Button(label: string, icon: string, onClicked: () => void) {
    return Widget.Button({
      className: "power-button",
      borderWidth: 0,
      css: `
					padding: 1rem 1.25rem;
					background: ${theme.secondary_color};
					border-radius: 10px; 
			`,
      onClicked() {
        setTimeout(() => {
          App.closeWindow("widgets");
        }, 0);
        onClicked();
      },
      child: Widget.Box({
        spacing: 10,
        children: [
          Widget.Icon({
            icon,
            size: 24,
            css: `
							color: ${theme.on_secondary_color};
						`,
          }),
          Widget.Label({
            label,
            css: `
							color: ${theme.on_secondary_color};
						`,
          }),
        ],
      }),
    });
  }
  return Widget.Box({
    css: `
			min-width: 400px;
			padding: 1rem;
			background-color: ${theme.bg_color};
			border-radius: 10px;
		`,
    vpack: "end",
    spacing: 10,
    children: [
      Button("Sleep", "moon", () => {
        Utils.execAsync([
          "/bin/bash",
          "-c",
          "hyprlock & sleep 1 && systemctl hybrid-sleep",
        ]);
      }),
      Button("Hibernate", "media-playback-pause", () => {
        Utils.execAsync([
          "/bin/bash",
          "-c",
          "hyprlock & sleep 1 && systemctl hibernate",
        ]);
      }),
      Button("Shutdown", "system-shutdown", () => {
        Utils.execAsync("systemctl poweroff");
      }),
      Button("Restart", "view-refresh", () => {
        Utils.execAsync("systemctl reboot");
      }),
    ],
  });
}
