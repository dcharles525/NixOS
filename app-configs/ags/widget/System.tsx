import { App, Astal, Gdk, Gtk } from "astal/gtk4"
import GLib from "gi://GLib"
import { Variable, exec, execAsync, interval } from "astal"
import { readFile } from "astal/file"

// System popover: CPU, RAM, GPU, disk in one place so the bar only carries
// a single "computer" module. Everything comes from /proc and /sys except
// GPU (nvidia-smi, desktop only) and disk usage (df). Polling only runs
// while a System window is visible; the bar module has its own cheap poll.
//
// Fans: every hwmon pwmN with a matching fanN_input gets a row. On the
// desktop that is the board's ITE Super I/O (out-of-tree it87 module, see
// hosts/desktop/configuration.nix). Hosts with no PWM driver get no card.

interface Stats {
  cpu: number        // 0-1
  cpuTemp: number    // °F, 0 if unknown
  load: string
  memUsed: number    // bytes
  memTotal: number
  swapUsed: number
  swapTotal: number
  gpu: {
    util: number
    memUsed: number
    memTotal: number
    temp: number
    fan: number      // 0-1, the card's own fan; read-only on Wayland
    name: string
  } | null
  diskUsed: number
  diskTotal: number
  diskBusy: number   // 0-1, fraction of interval the root device was busy
  fans: Fan[]
}

interface FanCh {
  id: string         // "hwmon5/pwm2"
  n: string          // channel number within the chip
  base: string       // /sys/class/hwmon/hwmon5
  chip: string       // hwmon name, e.g. it8689
  writable: boolean  // udev hands pwmN and pwmN_enable to group wheel
}

interface Fan {
  id: string
  rpm: number
  duty: number       // 0-1
  auto: boolean      // false only when pwmN_enable is 1 (manual)
}

// pwmN_enable values: 1 = manual duty, 2 = the chip's own curve, which is
// whatever Smart Fan is set to in the BIOS.
const PWM_MANUAL = 1
const PWM_AUTO = 2
// Lowest duty the slider offers. Nothing here knows which header is the CPU
// cooler, so no channel can be dragged to a stop.
const FAN_FLOOR = 0.2
// Manual duties are fixed, not a curve. Past this CPU temp every manual
// channel goes back to auto, popover open or not.
const FAILSAFE_C = 85

const FANS: FanCh[] = (() => {
  try {
    return exec([
      "sh",
      "-c",
      "ls -d /sys/class/hwmon/hwmon*/pwm[0-9] 2>/dev/null || true",
    ])
      .split("\n")
      .filter(Boolean)
      .map((pwm) => {
        const base = pwm.replace(/\/pwm\d$/, "")
        const n = pwm.slice(-1)
        return {
          id: `${base.split("/").pop()}/pwm${n}`,
          n,
          base,
          chip: readFile(`${base}/name`).trim(),
          writable:
            GLib.access(pwm, 2 /* W_OK */) === 0 &&
            GLib.access(`${pwm}_enable`, 2) === 0,
        }
      })
      .filter((f) =>
        GLib.file_test(`${f.base}/fan${f.n}_input`, GLib.FileTest.EXISTS))
  } catch {
    return []
  }
})()

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

function readCpuTempC(): number {
  try {
    const hwmon = "/sys/devices/platform/coretemp.0/hwmon"
    const raw = exec(["sh", "-c", `cat ${hwmon}/hwmon*/temp1_input`])
    return parseInt(raw, 10) / 1000 || 0
  } catch {
    return 0
  }
}

function readCpuTemp(): number {
  const c = readCpuTempC()
  return c ? toF(c) : 0
}

function toF(c: number): number {
  return Math.round(c * 9 / 5 + 32)
}

function num(path: string): number {
  return parseInt(readFile(path), 10) || 0
}

function readFans(): Fan[] {
  return FANS.map((f) => ({
    id: f.id,
    rpm: num(`${f.base}/fan${f.n}_input`),
    duty: num(`${f.base}/pwm${f.n}`) / 255,
    auto: num(`${f.base}/pwm${f.n}_enable`) !== PWM_MANUAL,
  }))
}

// Mode first, then duty: it87 answers EBUSY to a duty write in auto mode.
// The stats Variable is patched in place so the slider does not snap back
// to the old value while the next poll is still up to 2s away.
function fanWrite(f: FanCh, mode: number, duty?: number) {
  const pwm = `${f.base}/pwm${f.n}`
  let cmd = `echo ${mode} > ${pwm}_enable`
  if (duty !== undefined) {
    duty = Math.min(1, Math.max(FAN_FLOOR, duty))
    cmd += ` && echo ${Math.round(duty * 255)} > ${pwm}`
  }
  execAsync(["sh", "-c", cmd]).catch(console.error)
  const s = stats.get()
  stats.set({
    ...s,
    fans: s.fans.map((x) =>
      x.id === f.id
        ? { ...x, auto: mode !== PWM_MANUAL, duty: duty ?? x.duty }
        : x),
  })
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
    const fields = "utilization.gpu,memory.used,memory.total," +
      "temperature.gpu,fan.speed,name"
    const [util, used, total, temp, fan, ...name] = exec([
      "nvidia-smi",
      `--query-gpu=${fields}`,
      "--format=csv,noheader,nounits",
    ]).split(",").map((s) => s.trim())
    return {
      util: Number(util) / 100,
      memUsed: Number(used) * 1024 * 1024,
      memTotal: Number(total) * 1024 * 1024,
      temp: toF(Number(temp)),
      fan: Number(fan) / 100 || 0,
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
    fans: readFans(),
  }
}

const stats = Variable<Stats>(sample()).poll(2000, sample)
stats.stopPoll()

if (FANS.some((f) => f.writable)) {
  interval(10_000, () => {
    const manual = FANS.filter((f) =>
      f.writable && num(`${f.base}/pwm${f.n}_enable`) === PWM_MANUAL)
    if (!manual.length || readCpuTempC() < FAILSAFE_C) return
    manual.forEach((f) => fanWrite(f, PWM_AUTO))
    execAsync([
      "notify-send",
      "-u",
      "critical",
      "Fans back on auto",
      `CPU passed ${toF(FAILSAFE_C)}°F on a manual fan duty`,
    ]).catch(() => {})
  })
}

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

function FanRow({ fan }: { fan: FanCh }) {
  const me = (s: Stats) => s.fans.find((x) => x.id === fan.id)
  return (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
      <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
        <label label={`Fan ${fan.n}`} xalign={0} />
        <label
          cssClasses={["ep-pct"]}
          label={stats((s) => `${me(s)?.rpm ?? 0} rpm`)}
          xalign={0}
          hexpand
        />
        <button
          cssClasses={["mpris-btn"]}
          sensitive={fan.writable}
          onClicked={() => {
            const f = me(stats.get())
            if (!f) return
            if (f.auto) fanWrite(fan, PWM_MANUAL, f.duty)
            else fanWrite(fan, PWM_AUTO)
          }}
        >
          <label label={stats((s) => (me(s)?.auto ? "Auto" : "Manual"))} />
        </button>
      </box>
      <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
        <slider
          cssClasses={["ep-slider"]}
          hexpand
          min={FAN_FLOOR}
          max={1}
          step={0.01}
          sensitive={stats((s) => fan.writable && !(me(s)?.auto ?? true))}
          value={stats((s) => me(s)?.duty ?? 0)}
          onChangeValue={({ value }) => fanWrite(fan, PWM_MANUAL, value)}
        />
        <label
          cssClasses={["ep-pct"]}
          widthChars={4}
          xalign={1}
          label={stats((s) => pct(me(s)?.duty ?? 0))}
        />
      </box>
    </box>
  )
}

function Fans() {
  const chips = [...new Set(FANS.map((f) => f.chip))].join(" ")
  const hint = FANS.some((f) => f.writable)
    ? `manual floor ${pct(FAN_FLOOR)} · auto again at ${toF(FAILSAFE_C)}°F`
    : "read-only: no write access to pwm"
  return (
    <box
      cssClasses={["sys-row"]}
      orientation={Gtk.Orientation.VERTICAL}
      spacing={8}
    >
      <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
        <label cssClasses={["wifi-icon-inline"]} label="󰈐" />
        <label cssClasses={["sys-title"]} label="Fans" xalign={0} hexpand />
        <label cssClasses={["ep-pct"]} label={chips} />
      </box>
      {FANS.map((f) => <FanRow fan={f} />)}
      <label cssClasses={["hint"]} label={hint} xalign={0} />
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
                ? `${s.gpu.name} · ${gb(s.gpu.memUsed)} / ` +
                  `${gb(s.gpu.memTotal)} · ${s.gpu.temp}°F · ` +
                  `fan ${pct(s.gpu.fan)}`
                : "nvidia-smi unavailable"}
          />
        )}
        <Meter
          icon="󰋊"
          title="Disk"
          value={(s) => (s.diskTotal ? s.diskUsed / s.diskTotal : 0)}
          detail={(s) => `${gb(s.diskUsed)} / ${gb(s.diskTotal)} used · ${pct(s.diskBusy)} busy (${ROOT_DEV})`}
        />

        {FANS.length > 0 && <Fans />}

        <label cssClasses={["hint"]} label="Esc closes" xalign={1} />
      </box>
    </window>
  )
}
