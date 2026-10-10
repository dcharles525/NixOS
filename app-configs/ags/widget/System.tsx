import { App, Astal, Gdk, Gtk } from "astal/gtk4"
import GLib from "gi://GLib"
import { Variable, exec } from "astal"
import { readFile } from "astal/file"

// System popover: CPU, RAM, GPU, disk in one place so the bar only carries
// a single "computer" module. Everything comes from /proc and /sys except
// GPU (nvidia-smi, desktop only) and disk usage (df). Polling only runs
// while a System window is visible; the bar module has its own cheap poll.

interface Stats {
  cpu: number        // 0-1
  cpuTemp: number    // °F, 0 if unknown
  load: string
  memUsed: number    // bytes
  memTotal: number
  swapUsed: number
  swapTotal: number
  gpu: { util: number; memUsed: number; memTotal: number; temp: number; name: string } | null
  diskUsed: number
  diskTotal: number
  diskBusy: number   // 0-1, fraction of interval the root device was busy
}

const HAS_NVIDIA = GLib.find_program_in_path("nvidia-smi") !== null

// Root block device as /proc/diskstats names it (nvme1n1p2, dm-0, ...).
// findmnt prints "/dev/nvme1n1p2[/@]" on btrfs subvolumes, so strip that.
const ROOT_DEV = (() => {
  try {
    const src = exec(["findmnt", "-no", "SOURCE", "/"]).replace(/\[.*\]$/, "").trim()
    return exec(["realpath", src]).trim().replace(/^\/dev\//, "")
  } catch {
    return ""
  }
})()

let prevCpu = { idle: 0, total: 0 }
let prevDisk = { ticks: 0, at: 0 }

function readCpu(): number {
  const f = readFile("/proc/stat").split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
  const idle = f[3] + f[4]
  const total = f.reduce((a, b) => a + b, 0)
  const dIdle = idle - prevCpu.idle
  const dTotal = total - prevCpu.total
  prevCpu = { idle, total }
  return dTotal > 0 ? 1 - dIdle / dTotal : 0
}

function readCpuTemp(): number {
  try {
    const c = parseInt(exec(["sh", "-c", "cat /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input"]), 10) / 1000
    return Math.round(c * 9 / 5 + 32)
  } catch {
    return 0
  }
}

function readMem() {
  const kv: Record<string, number> = {}
  for (const line of readFile("/proc/meminfo").split("\n")) {
    const m = line.match(/^(\w+):\s+(\d+)/)
    if (m) kv[m[1]] = parseInt(m[2], 10) * 1024
  }
  return {
    memTotal: kv.MemTotal ?? 0,
    memUsed: (kv.MemTotal ?? 0) - (kv.MemAvailable ?? 0),
    swapTotal: kv.SwapTotal ?? 0,
    swapUsed: (kv.SwapTotal ?? 0) - (kv.SwapFree ?? 0),
  }
}

function readGpu(): Stats["gpu"] {
  if (!HAS_NVIDIA) return null
  try {
    const [util, used, total, temp, ...name] = exec([
      "nvidia-smi",
      "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,name",
      "--format=csv,noheader,nounits",
    ]).split(",").map((s) => s.trim())
    return {
      util: Number(util) / 100,
      memUsed: Number(used) * 1024 * 1024,
      memTotal: Number(total) * 1024 * 1024,
      temp: Math.round(Number(temp) * 9 / 5 + 32),
      name: name.join(",").replace(/^NVIDIA\s+/, ""),
    }
  } catch {
    return null
  }
}

function readDisk() {
  let diskUsed = 0, diskTotal = 0, diskBusy = 0
  try {
    const [size, used] = exec(["df", "-B1", "--output=size,used", "/"]).split("\n")[1].trim().split(/\s+/).map(Number)
    diskTotal = size
    diskUsed = used
  } catch {}
  // Field 13 of /proc/diskstats is io_ticks: ms the device spent doing I/O.
  // Delta over wall-clock delta = utilization, same number iostat's %util gives.
  const line = readFile("/proc/diskstats").split("\n").find((l) => l.trim().split(/\s+/)[2] === ROOT_DEV)
  if (line) {
    const ticks = Number(line.trim().split(/\s+/)[12])
    const at = GLib.get_monotonic_time() / 1000
    if (prevDisk.at > 0) diskBusy = Math.min(1, (ticks - prevDisk.ticks) / (at - prevDisk.at))
    prevDisk = { ticks, at }
  }
  return { diskUsed, diskTotal, diskBusy }
}

function sample(): Stats {
  return {
    cpu: readCpu(),
    cpuTemp: readCpuTemp(),
    load: readFile("/proc/loadavg").split(" ").slice(0, 3).join(" "),
    ...readMem(),
    gpu: readGpu(),
    ...readDisk(),
  }
}

const stats = Variable<Stats>(sample()).poll(2000, sample)
stats.stopPoll()

function gb(bytes: number): string {
  return `${(bytes / 1024 ** 3).toFixed(1)}G`
}

function pct(f: number): string {
  return `${Math.round(f * 100)}%`
}

function Meter({ icon, title, value, detail }: {
  icon: string
  title: string
  value: (s: Stats) => number
  detail: (s: Stats) => string
}) {
  return (
    <box cssClasses={["sys-row"]} orientation={Gtk.Orientation.VERTICAL} spacing={4}>
      <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
        <label cssClasses={["wifi-icon-inline"]} label={icon} />
        <label cssClasses={["sys-title"]} label={title} xalign={0} hexpand />
        <label cssClasses={["ep-pct"]} label={stats((s) => pct(value(s)))} />
      </box>
      <levelbar cssClasses={["sys-bar"]} minValue={0} maxValue={1} value={stats((s) => value(s))} />
      <label cssClasses={["hint"]} label={stats((s) => detail(s))} xalign={0} />
    </box>
  )
}

export default function System(monitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name={`system-${monitor.connector}`}
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
      setup={(self) => {
        self.connect("notify::visible", () => {
          const anyOpen = App.get_windows().some((w) => w.name.startsWith("system-") && w.visible)
          if (anyOpen && !stats.isPolling()) stats.startPoll()
          if (!anyOpen) stats.stopPoll()
        })
      }}
      onKeyPressed={(_self, keyval) => {
        if (keyval === Gdk.KEY_Escape) App.get_window(`system-${monitor.connector}`)?.set_visible(false)
      }}
    >
      <box
        cssClasses={["popover-body"]}
        orientation={Gtk.Orientation.VERTICAL}
        spacing={12}
        widthRequest={360}
        hexpand={false}
        halign={Gtk.Align.END}
      >
        <label cssClasses={["popover-title"]} label="System" xalign={0} />

        <Meter
          icon="󰍛"
          title="CPU"
          value={(s) => s.cpu}
          detail={(s) => `load ${s.load}${s.cpuTemp ? ` · ${s.cpuTemp}°F` : ""}`}
        />
        <Meter
          icon="󰘚"
          title="Memory"
          value={(s) => (s.memTotal ? s.memUsed / s.memTotal : 0)}
          detail={(s) =>
            `${gb(s.memUsed)} / ${gb(s.memTotal)}` +
            (s.swapTotal ? ` · swap ${gb(s.swapUsed)} / ${gb(s.swapTotal)}` : "")}
        />
        {HAS_NVIDIA && (
          <Meter
            icon="󰢮"
            title="GPU"
            value={(s) => s.gpu?.util ?? 0}
            detail={(s) =>
              s.gpu
                ? `${s.gpu.name} · ${gb(s.gpu.memUsed)} / ${gb(s.gpu.memTotal)} · ${s.gpu.temp}°F`
                : "nvidia-smi unavailable"}
          />
        )}
        <Meter
          icon="󰋊"
          title="Disk"
          value={(s) => (s.diskTotal ? s.diskUsed / s.diskTotal : 0)}
          detail={(s) => `${gb(s.diskUsed)} / ${gb(s.diskTotal)} used · ${pct(s.diskBusy)} busy (${ROOT_DEV})`}
        />

        <label cssClasses={["hint"]} label="Esc closes" xalign={1} />
      </box>
    </window>
  )
}
