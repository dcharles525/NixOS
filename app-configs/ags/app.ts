import { App, Astal, Gdk, Gtk } from "astal/gtk4"
import { exec, timeout } from "astal"
import style from "./style.scss"
import Hello from "./widget/Hello"
import Media from "./widget/Media"
import Bluetooth from "./widget/Bluetooth"
import Wifi from "./widget/Wifi"
import System from "./widget/System"

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

// Popover windows keyed by monitor connector, so hotplug can add and drop
// a whole set at once.
const perMonitor = new Map<string, Gtk.Window[]>()

function syncMonitors() {
  const live = new Set<string>()
  for (const m of App.get_monitors()) {
    const conn = m.connector
    if (!conn) continue
    live.add(conn)
    if (perMonitor.has(conn)) continue
    perMonitor.set(conn, [
      Hello(m),
      Media(m),
      Bluetooth(m),
      Wifi(m),
      System(m),
    ] as Gtk.Window[])
  }
  for (const [conn, wins] of perMonitor) {
    if (live.has(conn)) continue
    wins.forEach((w) => w.destroy())
    perMonitor.delete(conn)
  }
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
    syncMonitors()
    // Windows are per-monitor, so a monitor plugged in after startup has
    // none and toggles log `no window with name ...`. Rebuild on hotplug.
    // The connector can be unset when the signal fires, so retry shortly.
    const monitors = Gdk.Display.get_default()!.get_monitors()
    monitors.connect("items-changed", () => {
      syncMonitors()
      timeout(500, syncMonitors)
    })
  },
})
