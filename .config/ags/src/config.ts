import GObject from "types/@girs/gobject-2.0/gobject-2.0";
import { Audio, Media } from "./Media";
import { Notifications, notificationFadeOutMs } from "./Notifications";
import { PowerOptions } from "./PowerOptions";

function Widgets(monitor: number) {
  const visible = Variable(false);
  return Widget.Window({
    monitor,
    visible: false,
    name: "widgets",
    anchor: ["bottom", "right"],
    css: "background-color: rgba(0, 0, 0, 0);",
    expand: false,
    keymode: "exclusive",
    setup: (self) => {
      self.on("notify::visible", () => {
        visible.setValue(self.visible);
      });
    },
    child: Widget.Box({
      css: `
				padding: 2rem;
			`,
      spacing: 20,
      children: [
        PowerOptions(),
        Audio(),
        Media(),
        //
      ],
    }),
  }).keybind("Escape", () => {
    App.closeWindow("widgets");
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
