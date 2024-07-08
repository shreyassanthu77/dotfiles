import Gtk from "types/@girs/gtk-3.0/gtk-3.0";
import { Binding } from "types/service";

export interface ImageProps {
  url: string | Binding<any, any, string>;
  min_width?: string;
  min_height?: string;
  css?: string;
  fit?: "cover" | "contain" | "fill";
  aligh?: Gtk.Align;
}

export function Image({
  url,
  min_width: width = "64px",
  min_height: height = "64px",
  fit = "cover",
  css = "",
  aligh = Gtk.Align.CENTER,
}: ImageProps) {
  const cssFn = (url: string) => `
					min-width: ${width};
					min-height: ${height};
					background-image: url("${url.valueOf()}");
					background-size: ${fit};
					background-repeat: no-repeat;
					${css}
				`;
  return Widget.Box({
    halign: aligh,
    css: typeof url === "string" ? cssFn(url) : url.as(cssFn),
  });
}
