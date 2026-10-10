import { App, Astal, Gdk, Gtk } from "astal/gtk4"
import { bind } from "astal"
import BluetoothLib from "gi://AstalBluetooth"

function DeviceRow({ device }: { device: BluetoothLib.Device }) {
  return (
    <box
      cssClasses={["bt-device"]}
      orientation={Gtk.Orientation.HORIZONTAL}
      spacing={8}
    >
      <label
        xalign={0}
        hexpand
        ellipsize={3}
        maxWidthChars={22}
        label={bind(device, "alias").as((a) => a || device.name || device.address)}
      />
      <label
        cssClasses={["hint"]}
        label={bind(device, "batteryPercentage").as((b) => (b > 0 ? `${Math.round(b * 100)}%` : ""))}
      />
      <button
        cssClasses={["ep-mute"]}
        onClicked={() => {
          if (device.connected) device.disconnect_device()
          else device.connect_device()
        }}
      >
        <label
          label={bind(device, "connected").as((c) => (c ? "⏹" : "▶"))}
        />
      </button>
    </box>
  )
}

function DiscoveredRow({ device }: { device: BluetoothLib.Device }) {
  return (
    <box
      cssClasses={["bt-device"]}
      orientation={Gtk.Orientation.HORIZONTAL}
      spacing={8}
    >
      <label
        xalign={0}
        hexpand
        ellipsize={3}
        maxWidthChars={26}
        label={bind(device, "alias").as((a) => a || device.name || device.address)}
      />
      <button
        cssClasses={["ep-mute"]}
        onClicked={() => device.pair()}
      >
        <label label="Pair" />
      </button>
    </box>
  )
}

export default function Bluetooth(monitor: Gdk.Monitor) {
  const bt = BluetoothLib.get_default()
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name={`bluetooth-${monitor.connector}`}
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
        if (keyval === Gdk.KEY_Escape) App.get_window(`bluetooth-${monitor.connector}`)?.set_visible(false)
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
        {/* Header + power toggle */}
        <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
          <label cssClasses={["popover-title"]} label="Bluetooth" xalign={0} hexpand />
          <button
            cssClasses={["mpris-btn"]}
            onClicked={() => {
              const a = bt.adapter
              if (a) a.set_powered(!a.powered)
            }}
          >
            <label label={bind(bt, "isPowered").as((p) => (p ? "On" : "Off"))} />
          </button>
        </box>

        <box cssClasses={["divider"]} heightRequest={1} />

        {/* Paired */}
        <label cssClasses={["section-label"]} label="Paired" xalign={0} />
        <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
          {bind(bt, "devices").as((devs) => {
            const paired = devs.filter((d) => d.paired)
            return paired.length === 0
              ? (<label cssClasses={["hint"]} label="No paired devices" xalign={0} />)
              : paired.map((d) => <DeviceRow device={d} />)
          })}
        </box>

        <box cssClasses={["divider"]} heightRequest={1} />

        {/* Discovered */}
        <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
          <label cssClasses={["section-label"]} label="Nearby" xalign={0} hexpand />
          <button
            cssClasses={["mpris-btn"]}
            onClicked={() => {
              const a = bt.adapter
              if (!a) return
              if (a.discovering) a.stop_discovery()
              else a.start_discovery()
            }}
          >
            {/* bt.adapter may be null at boot; take a static label to
                avoid crashing bind() at instantiation. State-tracked label
                would require a nested bind that recreates on adapter add. */}
            <label label="Scan" />
          </button>
        </box>
        <Gtk.ScrolledWindow
          cssClasses={["scroll"]}
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
          vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
          minContentHeight={80}
          maxContentHeight={260}
          propagateNaturalHeight
        >
          <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
            {bind(bt, "devices").as((devs) => {
              const unpaired = devs.filter((d) => !d.paired)
              return unpaired.length === 0
                ? (<label cssClasses={["hint"]} label="Nothing new — tap Scan" xalign={0} />)
                : unpaired.map((d) => <DiscoveredRow device={d} />)
            })}
          </box>
        </Gtk.ScrolledWindow>

        <label cssClasses={["hint"]} label="Esc closes" xalign={1} />
      </box>
    </window>
  )
}
