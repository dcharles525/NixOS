import { App, Astal, Gdk, Gtk } from "astal/gtk4"
import { Variable, execAsync, exec, bind } from "astal"

// WiFi popover backed by iwctl. iwd's DBus API would be cleaner but this
// keeps the code surface tight — we shell out for scan/list/connect and
// parse iwctl's fixed-width table output (stripping ANSI first).

const IFACE = "wlan0"

interface Network {
  ssid: string
  security: string  // "open" | "psk" | "8021x" | ...
  signal: number    // 0-4 stars
  connected: boolean
  known: boolean
}

const stripAnsi = (s: string) => s.replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "")

// Live state — SSID/signal/IP/enabled — polled every 3s.
const state = Variable({
  ssid: "",
  signal: 0,
  ip: "",
  enabled: true,
}).poll(3000, () => {
  let ssid = "", signal = 0, ip = "", enabled = true
  try {
    const link = exec(["iw", "dev", IFACE, "link"])
    ssid = link.match(/SSID:\s*(.+)/)?.[1].trim() ?? ""
    signal = parseInt(link.match(/signal:\s*(-?\d+)/)?.[1] ?? "0", 10)
  } catch {}
  try {
    const ipOut = exec(["ip", "-4", "-o", "addr", "show", IFACE])
    ip = ipOut.match(/inet\s+([\d.]+)/)?.[1] ?? ""
  } catch {}
  try {
    const rfk = exec(["rfkill", "list", "wifi"])
    enabled = !/Soft blocked:\s*yes/.test(rfk)
  } catch {}
  return { ssid, signal, ip, enabled }
})

// Network list + scanning flag + inline passphrase selection state.
const networks = Variable<Network[]>([])
const scanning = Variable(false)
const selected = Variable<Network | null>(null)
const pwText = Variable("")

async function refresh() {
  const nets = await listNetworks()
  networks.set(nets)
}

async function scanAndRefresh() {
  scanning.set(true)
  try { await execAsync(["iwctl", "station", IFACE, "scan"]) } catch {}
  setTimeout(async () => {
    await refresh()
    scanning.set(false)
  }, 2500)
}

async function listNetworks(): Promise<Network[]> {
  let raw = ""
  try { raw = await execAsync(["iwctl", "station", IFACE, "get-networks"]) } catch { return [] }
  raw = stripAnsi(raw)

  const lines = raw.split("\n")
  const headerIdx = lines.findIndex((l) => /Network name/.test(l) && /Security/.test(l) && /Signal/.test(l))
  if (headerIdx < 0) return []

  const nets: Network[] = []
  for (const raw of lines.slice(headerIdx + 2)) {
    const line = stripAnsi(raw).trimEnd()
    if (!line.trim() || /^\s*-+\s*$/.test(line)) continue
    // Row: "[ >] SSID   security   stars"
    const connected = /^\s{0,4}>/.test(line)
    const body = line.replace(/^\s{0,4}>?\s+/, "")
    const parts = body.split(/\s{2,}/).filter(Boolean)
    if (parts.length < 3) continue
    const [ssid, security, stars] = [parts[0], parts[1], parts[parts.length - 1]]
    nets.push({
      ssid,
      security,
      signal: (stars.match(/\*/g) || []).length,
      connected,
      known: false,
    })
  }

  // Merge in known-network flags.
  try {
    const raw = stripAnsi(await execAsync(["iwctl", "known-networks", "list"]))
    const knownSsids = new Set<string>()
    const lines = raw.split("\n")
    const headerIdx = lines.findIndex((l) => /Name/.test(l) && /Security/.test(l))
    if (headerIdx >= 0) {
      for (const raw of lines.slice(headerIdx + 2)) {
        const line = raw.trim()
        if (!line || /^-+$/.test(line)) continue
        const parts = line.split(/\s{2,}/).filter(Boolean)
        if (parts.length >= 1) knownSsids.add(parts[0])
      }
    }
    nets.forEach((n) => { if (knownSsids.has(n.ssid)) n.known = true })
  } catch {}

  return nets
}

async function connect(ssid: string, passphrase?: string) {
  const args = passphrase
    ? ["iwctl", "--passphrase", passphrase, "station", IFACE, "connect", ssid]
    : ["iwctl", "station", IFACE, "connect", ssid]
  try { await execAsync(args) } catch (e) { console.error("connect failed:", e) }
  await refresh()
}

async function disconnect() {
  try { await execAsync(["iwctl", "station", IFACE, "disconnect"]) } catch {}
  await refresh()
}

async function forget(ssid: string) {
  try { await execAsync(["iwctl", "known-networks", ssid, "forget"]) } catch {}
  await refresh()
}

function signalIcon(dbmOrStars: number, fromDbm = true): string {
  const bars = fromDbm
    ? (dbmOrStars === 0 ? 0 : dbmOrStars >= -55 ? 4 : dbmOrStars >= -65 ? 3 : dbmOrStars >= -75 ? 2 : 1)
    : dbmOrStars
  return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][bars]
}

function NetworkRow({ net }: { net: Network }) {
  return (
    <box cssClasses={["wifi-row"]} orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
      <label cssClasses={["wifi-icon-inline"]} label={signalIcon(net.signal, false)} />
      <box orientation={Gtk.Orientation.VERTICAL} spacing={0} hexpand halign={Gtk.Align.START}>
        <label
          xalign={0}
          hexpand
          ellipsize={3}
          maxWidthChars={22}
          label={net.connected ? `${net.ssid}  · connected` : net.ssid}
        />
        <label
          cssClasses={["hint"]}
          xalign={0}
          label={`${net.security === "open" ? "open" : "🔒 " + net.security}${net.known ? "  · saved" : ""}`}
        />
      </box>
      {net.connected ? (
        <button cssClasses={["mpris-btn"]} onClicked={() => disconnect()}>
          <label label="Disconnect" />
        </button>
      ) : (
        <button
          cssClasses={["mpris-btn"]}
          onClicked={() => {
            // Known or open networks can be connected directly.
            if (net.known || net.security === "open") {
              connect(net.ssid)
            } else {
              // Otherwise expand the inline passphrase form.
              selected.set(net)
              pwText.set("")
            }
          }}
        >
          <label label={net.known ? "Connect" : "Connect…"} />
        </button>
      )}
    </box>
  )
}

export default function Wifi(monitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name={`wifi-${monitor.connector}`}
      cssClasses={["popover"]}
      gdkmonitor={monitor}
      application={App}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.ON_DEMAND}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP | RIGHT}
      marginTop={56}
      marginRight={0}
      visible={false}
      onKeyPressed={(_self, keyval) => {
        if (keyval === Gdk.KEY_Escape) App.get_window(`wifi-${monitor.connector}`)?.set_visible(false)
      }}
    >
      <box
        cssClasses={["popover-body"]}
        orientation={Gtk.Orientation.VERTICAL}
        spacing={10}
        widthRequest={360}
        hexpand={false}
        halign={Gtk.Align.END}
      >
        {/* Header + soft toggle */}
        <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
          <label cssClasses={["popover-title"]} label="Wi-Fi" xalign={0} hexpand />
          <button
            cssClasses={["mpris-btn"]}
            onClicked={() => {
              const on = state.get().enabled
              execAsync(["rfkill", on ? "block" : "unblock", "wifi"])
              setTimeout(() => state.set(state.get()), 200)
            }}
          >
            <label label={state((s) => (s.enabled ? "On" : "Off"))} />
          </button>
        </box>

        <box cssClasses={["divider"]} heightRequest={1} />

        {/* Current connection card */}
        <box cssClasses={["mpris-card"]} orientation={Gtk.Orientation.VERTICAL} spacing={4}>
          <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
            <label cssClasses={["wifi-icon"]} label={state((s) => signalIcon(s.signal))} />
            <label
              cssClasses={["mpris-title"]}
              xalign={0}
              hexpand
              ellipsize={3}
              label={state((s) => s.ssid || "Not connected")}
            />
          </box>
          <label
            cssClasses={["mpris-artist"]}
            xalign={0}
            label={state((s) => (s.ssid ? `${s.ip || "no IP"}  ·  ${s.signal} dBm` : "No network"))}
          />
        </box>

        {/* Scan header */}
        <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
          <label cssClasses={["section-label"]} label="Networks" xalign={0} hexpand />
          <button cssClasses={["mpris-btn"]} onClicked={() => scanAndRefresh()}>
            <label label={scanning((s) => (s ? "scanning…" : "Scan"))} />
          </button>
        </box>

        {/* Scrollable network list */}
        <Gtk.ScrolledWindow
          cssClasses={["scroll"]}
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
          vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
          minContentHeight={80}
          maxContentHeight={260}
          propagateNaturalHeight
        >
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
            {networks((nets) =>
              nets.length === 0
                ? (<label cssClasses={["hint"]} label="No networks — tap Scan" xalign={0} />)
                : nets.map((n) => <NetworkRow net={n} />),
            )}
          </box>
        </Gtk.ScrolledWindow>

        {/* Inline passphrase entry for the selected unknown network */}
        {selected((s) =>
          !s ? (<box visible={false} />) : (
            <box cssClasses={["mpris-card"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
              <label xalign={0} label={`Connect to ${s.ssid}`} />
              <box orientation={Gtk.Orientation.HORIZONTAL} spacing={4}>
                <entry
                  hexpand
                  visibility={false}
                  placeholderText="Passphrase"
                  onChanged={(self) => pwText.set(self.text)}
                  onActivate={async () => {
                    await connect(s.ssid, pwText.get())
                    selected.set(null)
                    pwText.set("")
                  }}
                />
                <button
                  cssClasses={["mpris-btn"]}
                  onClicked={async () => {
                    await connect(s.ssid, pwText.get())
                    selected.set(null)
                    pwText.set("")
                  }}
                >
                  <label label="OK" />
                </button>
                <button
                  cssClasses={["mpris-btn"]}
                  onClicked={() => {
                    selected.set(null)
                    pwText.set("")
                  }}
                >
                  <label label="✕" />
                </button>
              </box>
            </box>
          ),
        )}

        {/* Delegate rich management to iwgtk */}
        <button
          cssClasses={["mpris-btn"]}
          onClicked={() => {
            execAsync(["iwgtk"])
            App.get_window(`wifi-${monitor.connector}`)?.set_visible(false)
          }}
        >
          <label label="Manage networks…" />
        </button>

        <label cssClasses={["hint"]} label="Esc closes" xalign={1} />
      </box>
    </window>
  )
}
