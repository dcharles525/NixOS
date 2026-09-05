import { App, Astal, Gdk, Gtk } from "astal/gtk4"

// Minimal proof-of-life popover. Anchored top-right, dismissable with Esc.
// Toggled via: ags request 'toggle hello'
export default function Hello(monitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor
  return (
    <window
      name={`hello-${monitor.connector}`}
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
        if (keyval === Gdk.KEY_Escape) App.get_window(`hello-${monitor.connector}`)?.set_visible(false)
      }}
    >
      <box cssClasses={["popover-body"]} orientation={Gtk.Orientation.VERTICAL} spacing={12}>
        <label cssClasses={["popover-title"]} label="AGS is alive 👋" />
        <label label="You're seeing the widget shell." xalign={0} />
        <label cssClasses={["hint"]} label="Press Esc to close." xalign={0} />
      </box>
    </window>
  )
}
