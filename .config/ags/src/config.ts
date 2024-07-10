import { Audio, Media } from "./Media";
import { Notifications, notificationFadeOutMs } from "./Notifications";

function Widgets(monitor: number) {
  return Widget.Window({
    monitor,
    visible: false,
    name: "widgets",
    anchor: ["bottom", "right"],
    css: "background-color: rgba(0, 0, 0, 0);",
    expand: false,
    child: Widget.Box({
      css: `
				padding: 2rem;
			`,
      spacing: 20,
      children: [
        Audio(),
        Media(),
        //
      ],
    }),
  });
}

App.applyCss(`
	.hidden {
		opacity: 0;
		transition: opacity ${notificationFadeOutMs}ms;
	}
`);
App.config({
  windows: [Notifications(0), Widgets(0)],
});
