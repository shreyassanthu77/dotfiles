import { theme } from "./theme";
import Gtk from "types/@girs/gtk-3.0/gtk-3.0";
import { Stream } from "types/service/audio";
import { MprisPlayer } from "types/service/mpris";
import { Image } from "./Image";
import Box from "types/widgets/box";

App.applyCss(`
	scale trough {
		background-color: ${theme.secondary_color};
	}

	scale trough highlight {
		background-color: ${theme.accent_color};
	}
`);

const audio = await Service.import("audio");
export function Audio() {
  function Slider(stream: Stream, name?: string) {
    return Widget.Box({
      vertical: true,
      children: [
        Widget.Label({
          halign: Gtk.Align.START,
          css: `
						font-size: 1.2em;
						font-weight: 500;
						margin-bottom: 0.5rem;
					`,
          label: stream
            .bind("volume")
            .transform(
              (v) => `${name ?? stream.name} ${(v * 100).toFixed(1)}%`,
            ),
        }),
        Widget.Slider({
          min: 0,
          max: 100,
          drawValue: false,
          css: `
						padding: 2px 0;
						border: none;
						outline-color: ${theme.on_secondary_color}
					`,
          onChange({ value }) {
            stream.volume = value / 100;
          },
          value: stream.bind("volume").transform((v) => v * 100),
        }),
      ],
    });
  }

  function ApplicationSliders() {
    return Widget.Box({
      vertical: true,
      css: `
				margin: .5rem;
			`,
      spacing: 10,
      children: [
        Widget.Label({
          halign: Gtk.Align.START,
          label: audio.bind("apps").as((a) => `Applications (${a.length})`),
          css: `
					font-size: 1.35em;
					font-weight: 900;
				`,
        }),
        Widget.Box({
          vertical: true,
          spacing: 10,
          children: audio.bind("apps").as((a) => a.map((app) => Slider(app))),
        }),
        Widget.Label({
          visible: audio.bind("apps").transform((apps) => apps.length === 0),
          css: `
						font-weight: 300;
					`,
          label: "No applications playing media",
        }),
      ],
    });
  }

  return Widget.Box({
    css: `
			min-width: 400px;
			padding: 1rem;
			background-color: ${theme.bg_color};
			border-radius: 10px;
		`,
    vertical: true,
    vpack: "end",
    spacing: 10,
    children: [
      Widget.Label({
        halign: Gtk.Align.START,
        label: "Global Volume",
        css: `
					font-size: 1.35em;
					font-weight: 900;
					margin-bottom: .5rem;
				`,
      }),
      Slider(audio.speaker, "Speaker"),
      Slider(audio.microphone, "Microphone"),
      ApplicationSliders(),
    ],
  });
}

const mpris = await Service.import("mpris");
export function Media() {
  function lengthStr(length: number) {
    const min = Math.floor(length / 60);
    const sec = Math.floor(length % 60);
    const sec0 = sec < 10 ? "0" : "";
    return `${min}:${sec0}${sec}`;
  }
  function PlayerInfo(player: MprisPlayer) {
    return Widget.Box({
      vertical: true,
      spacing: 10,
      children: [
        Widget.Label({
          justification: "left",
          halign: Gtk.Align.START,
          xalign: 0,
          label: player.bind("track_title"),
          maxWidthChars: 60,
          wrap: true,
          css: `
								font-size: 1.35em;
								font-weight: 900;
							`,
        }),
        Widget.Label({
          halign: Gtk.Align.START,
          label: player.bind("track_artists").as((a) => a.join(", ")),
          maxWidthChars: 30,
          truncate: "end",
          css: `
								font-size: 1.2em;
								font-weight: 500;
							`,
        }),
        Widget.Label({
          halign: Gtk.Align.START,
          label: player.bind("track_album"),
          css: `
								font-size: 1em;
								font-weight: 300;
							`,
        }),
      ],
    });
  }

  function PlayerSlider(player: MprisPlayer) {
    return Widget.Box({
      vertical: true,
      children: [
        Widget.Slider({
          css: `
						padding: 2px 0;
						border: none;
						outline-color: ${theme.on_secondary_color}
					`,
          draw_value: false,
          on_change: ({ value }) => (player.position = value * player.length),
          visible: player.bind("length").as((l) => l > 0),
          setup: (self) => {
            function update() {
              const value = player.position / player.length;
              self.value = value > 0 ? value : 0;
            }
            self.hook(player, update);
            self.hook(player, update, "position");
            self.poll(1000, update);
          },
        }),
        Widget.Box({
          hexpand: true,
          children: [
            Widget.Label({
              hpack: "start",
              setup: (self) => {
                const update = (_: unknown, time: number) => {
                  self.label = lengthStr(time || player.position);
                  self.visible = player.length > 0;
                };

                self.hook(player, update, "position");
                self.poll(1000, update as any);
              },
            }),
            Widget.Box({ hexpand: true }),
            Widget.Label({
              hpack: "end",
              visible: player.bind("length").transform((l) => l > 0),
              label: player.bind("length").transform(lengthStr),
            }),
          ],
        }),
      ],
    });
  }

  function PlayerControls(player: MprisPlayer) {
    return Widget.Box({
      spacing: 10,
      children: [
        Widget.Box({ hexpand: true }),
        Widget.Button({
          css: `
						padding: .5rem .7rem; 
						outline-width: 2px;
						outline-style: solid;
						outline-color: ${theme.on_secondary_color};`,
          onClicked: () => player.previous(),
          child: Widget.Icon({
            icon: "media-skip-backward-symbolic",
          }),
        }),
        Widget.Button({
          css: `
						padding: .5rem .7rem;
						background: ${theme.accent_color};
						color: ${theme.on_accent_color};
						outline-width: 2px;
						outline-style: solid;
						outline-color: ${theme.on_secondary_color};`,
          onClicked: () => player.playPause(),
          child: Widget.Icon({
            icon: player.bind("play_back_status").as((status) => {
              switch (status) {
                case "Playing":
                  return "media-playback-pause-symbolic";
                case "Paused":
                  return "media-playback-start-symbolic";
                default:
                  return "media-playback-start-symbolic";
              }
            }),
          }),
        }),
        Widget.Button({
          css: `padding: .5rem .7rem;
						outline-width: 2px;
						outline-style: solid;
						outline-color: ${theme.on_secondary_color};`,
          onClicked: () => player.next(),
          child: Widget.Icon({
            icon: "media-skip-forward-symbolic",
          }),
        }),
        Widget.Box({ hexpand: true }),
      ],
    });
  }

  function Player(player: MprisPlayer) {
    return Widget.Box({
      attribute: {
        name: player.bus_name,
      },
      spacing: 10,
      vertical: true,
      visible: player.bind("length").transform((l) => l > 0),
      css: `
				background-color: ${theme.bg_color};
				padding: 1rem;
				border-radius: 10px;
			`,
      children: [
        Widget.Box({
          spacing: 10,
          children: [
            Image({
              min_width: "120px",
              min_height: "120px",
              css: `
						border-radius: 10px;
					`,
              url: player.bind("track_cover_url"),
            }),
            PlayerInfo(player),
          ],
        }),
        PlayerSlider(player),
        PlayerControls(player),
      ],
    });
  }

  const numPlayers = Variable(0);

  function onPlayerAdded(self: Box<Gtk.Widget, unknown>, name?: string) {
    if (!name) return;
    const player = mpris.getPlayer(name);
    if (!player) return;
    self.children = [Player(player), ...self.children];
    numPlayers.setValue(numPlayers.value + 1);
  }
  function onPlayerClosed(self: Box<Gtk.Widget, unknown>, name?: string) {
    if (!name) return;
    self.children = self.children.filter(
      (child: any) => child?.attribute?.name !== name,
    );
    numPlayers.setValue(numPlayers.value - 1);
  }

  return Widget.Box({
    vertical: true,
    vpack: "end",
    spacing: 10,
    css: `
			min-width: 400px;
			border-radius: 10px;
		`,
    setup(self) {
      self
        .hook(mpris, onPlayerAdded, "player-added")
        .hook(mpris, onPlayerClosed, "player-closed");
    },
    children: [
      Widget.Label({
        visible: numPlayers.bind().as((n) => n === 0),
        label: "No media players active",
        css: `
						background-color: ${theme.bg_color};
							font-weight: 300;
							padding: 1rem;
							margin-bottom: .5rem;
						`,
      }),
    ] as Gtk.Widget[],
  });
}
