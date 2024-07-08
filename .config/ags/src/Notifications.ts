import { type Notification } from "types/service/notifications";
import type Label from "types/widgets/label";
import { theme } from "./theme";
import { Image } from "./Image";

const notifications = await Service.import("notifications");
export const notificationFadeOutMs = 500;

function NotificationIcon(notification: Notification) {
  const img = notification.image ?? notification.app_icon ?? "";
  if (!img) return Widget.Box({});
  return Image({
    url: img,
    min_width: "120px",
    min_height: "120px",
    css: `
					border-radius: 10px;
				`,
  });
}

function NotificationInfo(notification: Notification) {
  const children: Label<unknown>[] = [];

  if (notification.app_name) {
    children.push(
      Widget.Label({
        label: notification.app_name,
        justification: "left",
        wrap: true,
        use_markup: true,
        xalign: 0,
        css: `
						min-width: 200px;
						font-size: 1.2em;
						font-weight: 900;
					`,
      }),
    );
  }

  if (notification.summary) {
    children.push(
      Widget.Label({
        label: notification.summary,
        justification: "left",
        wrap: true,
        use_markup: true,
        xalign: 0,
        css: `
					min-width: 200px;
					font-size: 1em;
					font-weight: bold;
				`,
      }),
    );
  }

  if (notification.body) {
    children.push(
      Widget.Label({
        setup(self) {
          setTimeout(() => {
            self.set_markup(notification.body);
          });
        },
        justification: "left",
        wrap: true,
        use_markup: true,
        useMarkup: true,
        xalign: 0,
        css: `
						min-width: 200px;
						font-size: 0.8em;
					`,
      }),
    );
  }

  return Widget.Box({
    vertical: true,
    spacing: 10,
    children,
  });
}

function NotificationActions(notification: Notification) {
  if (!notification.actions) return Widget.Box({});
  return Widget.Box({
    spacing: 10,
    children: notification.actions.map((action, i) => {
      const background = i === 0 ? theme.accent_color : theme.primary_color;
      const color = i === 0 ? theme.on_accent_color : theme.on_primary_color;
      return Widget.Button({
        label: action.label,
        css: `
						background: ${background};
						color: ${color};
					`,
        onClicked(self) {
          let current = self as any;
          while (!current.attribute?.id) {
            current = current.parent;
          }
          current.attribute.active = false;
          current.attribute.destroy = true;
          notifications.InvokeAction(notification.id, action.id);
          notification.dismiss();
        },
      });
    }),
  });
}

function NotificationCard(notification: Notification) {
  return Widget.EventBox({
    attribute: {
      id: notification.id,
      active: false,
      destroy: false,
    },
    onHover(self) {
      self.attribute.active = true;
    },
    onHoverLost(self) {
      self.attribute.active = false;
      if (self.attribute.destroy) {
        setTimeout(
          notification.dismiss.bind(notifications),
          notifications.popupTimeout,
        );
      }
    },
    child: Widget.Box({
      vertical: true,
      css: `
					padding: 1rem 2rem;
					background-color: ${theme.bg_color};
					border-radius: 10px;
				`,
      spacing: 10,
      children: [
        Widget.Box({
          spacing: 20,
          children: [
            NotificationIcon(notification),
            NotificationInfo(notification),
          ],
        }),
        NotificationActions(notification),
      ],
    }),
  });
}

export function Notifications(monitor: number) {
  const list = Widget.Box({
    vertical: true,
    spacing: 10,
    css: `
				margin: 2rem;
			`,
    children: notifications.notifications.map(NotificationCard),
  });

  function onNotified(_: unknown, id: number) {
    const newNotification = notifications.getNotification(id);
    if (newNotification) {
      list.children = [NotificationCard(newNotification), ...list.children];
    }
  }

  function onDismissed(_: unknown, id: number) {
    const n = list.children.find((child) => child.attribute.id === id);
    if (!n) return;
    if (n.attribute.active) {
      n.attribute.destroy = true;
      return;
    }
    n.toggleClassName("hidden");
    setTimeout(n.destroy.bind(n), notificationFadeOutMs);
  }

  list
    .hook(notifications, onNotified, "notified")
    .hook(notifications, onDismissed, "dismissed");

  return Widget.Window({
    monitor,
    name: "notification",
    anchor: ["top", "right"],
    css: `
			min-width: 2px;
			min-height: 2px;
			background-color: rgba(0, 0, 0, 0);
		`,
    child: Widget.Scrollable({
      css: `
				min-width: 500px;
				min-height: 1080px;
			`,
      child: list,
    }),
  });
}
