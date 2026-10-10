import { App, Astal, Gdk } from "astal/gtk4"
import { exec } from "astal"
import style from "./style.scss"
import Hello from "./widget/Hello"
import Media from "./widget/Media"
import Bluetooth from "./widget/Bluetooth"
import Wifi from "./widget/Wifi"

// One instance of each popover per monitor, named "<base>-<monitor-name>"
// (e.g. "media-DP-1"). Toggling from the bar routes to the popover on the
// currently-focused monitor via `hyprctl monitors -j`.
function focusedMonitorName(): string {
  try {
    const raw = exec(["hyprctl", "monitors", "-j"])
    const monitors = JSON.parse(raw)
    return monitors.find((m: any) => m.focused)?.name ?? ""
  } catch {
    return ""
  }
}

function toggleOnFocused(base: string) {
  const target = focusedMonitorName()
  const win = App.get_window(`${base}-${target}`)
  if (!win) return

  const willShow = !win.visible
  // Popovers are mutually exclusive — opening one always closes every other,
  // including copies of any popover on other monitors. Only the just-toggled
  // window (if we're showing it) stays visible.
  for (const w of App.get_windows()) {
    if (w.name !== win.name) w.set_visible(false)
  }
  win.set_visible(willShow)
}

function hideAll() {
  for (const w of App.get_windows()) w.set_visible(false)
}

App.start({
  css: style,
  requestHandler(request, res) {
    const parts = request.trim().split(/\s+/)
    const cmd = parts[0]
    const arg = parts[1]

    switch (cmd) {
      case "toggle":
        if (!arg) return res("toggle needs a name")
        toggleOnFocused(arg)
        return res("ok")
      case "show":
        // Fallback to global lookup for single-monitor cases
        App.get_window(arg)?.set_visible(true)
        return res("ok")
      case "hide":
        if (arg) App.get_window(arg)?.set_visible(false)
        else hideAll()
        return res("ok")
      case "quit":
        App.quit()
        return res("bye")
      default:
        return res(`unknown request: ${request}`)
    }
  },
  main() {
    App.get_monitors().forEach((m) => {
      Hello(m)
      Media(m)
      Bluetooth(m)
      Wifi(m)
    })
  },
})
