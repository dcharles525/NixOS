import { App, Astal, Gdk, Gtk } from "astal/gtk4"
import { bind } from "astal"
import Wp from "gi://AstalWp"
import Mpris from "gi://AstalMpris"

function fmt(sec: number): string {
  if (!isFinite(sec) || sec < 0) return "--:--"
  const m = Math.floor(sec / 60)
  const s = Math.floor(sec % 60)
  return `${m}:${s.toString().padStart(2, "0")}`
}

function PlayerCard({ player }: { player: Mpris.Player }) {
  return (
    <box cssClasses={["mpris-card"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <label
        cssClasses={["mpris-title"]}
        label={bind(player, "title").as((t) => t || "Unknown title")}
        xalign={0}
        ellipsize={3 /* PANGO_ELLIPSIZE_END */}
        maxWidthChars={40}
      />
      <label
        cssClasses={["mpris-artist"]}
        label={bind(player, "artist").as((a) => a || "")}
        xalign={0}
        ellipsize={3}
        maxWidthChars={40}
      />
      <box orientation={Gtk.Orientation.HORIZONTAL} spacing={12} halign={Gtk.Align.CENTER}>
        <button
          cssClasses={["mpris-btn"]}
          onClicked={() => player.previous()}
          sensitive={bind(player, "canGoPrevious")}
        >
          <label label="󰒮" />
        </button>
        <button
          cssClasses={["mpris-btn", "mpris-play"]}
          onClicked={() => player.play_pause()}
        >
          <label
            label={bind(player, "playbackStatus").as((s) =>
              s === Mpris.PlaybackStatus.PLAYING ? "󰏦" : "󰐊",
            )}
          />
        </button>
        <button
          cssClasses={["mpris-btn"]}
          onClicked={() => player.next()}
          sensitive={bind(player, "canGoNext")}
        >
          <label label="󰒭" />
        </button>
      </box>
      <label
        cssClasses={["hint"]}
        xalign={1}
        label={bind(player, "identity").as((id) => id || "")}
      />
    </box>
  )
}

function EndpointRow({ label, endpoint }: { label: string; endpoint: Wp.Endpoint }) {
  return (
    <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
      <button
        cssClasses={["ep-mute"]}
        onClicked={() => endpoint.set_mute(!endpoint.mute)}
      >
        <label
          label={bind(endpoint, "mute").as((m) =>
            label === "Mic"
              ? (m ? "󰍭" : "󰍬")   // mdi microphone-off / microphone
              : (m ? "󰸈" : "󰕾"),  // mdi volume-mute / volume-high
          )}
        />
      </button>
      <slider
        cssClasses={["ep-slider"]}
        hexpand
        min={0}
        max={1}
        step={0.01}
        value={bind(endpoint, "volume")}
        onChangeValue={({ value }) => endpoint.set_volume(value)}
      />
      <label
        cssClasses={["ep-pct"]}
        widthChars={4}
        xalign={1}
        label={bind(endpoint, "volume").as((v) => `${Math.round(v * 100)}%`)}
      />
    </box>
  )
}

// Firefox (and some other browsers) expose one MPRIS instance per tab that
// has active media, so YouTube+SoundCloud simultaneously → two entries with
// identical identity/title/artist. Collapse duplicates to the first one so
// the UI shows one card per actual "thing playing".
function dedupePlayers(players: Mpris.Player[]): Mpris.Player[] {
  const seen = new Set<string>()
  return players.filter((p) => {
    const key = `${p.identity}::${p.title}::${p.artist}`
    if (seen.has(key)) return false
    seen.add(key)
    return true
  })
}

export default function Media(monitor: Gdk.Monitor) {
  const wp = Wp.get_default()
  const mpris = Mpris.get_default()
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name={`media-${monitor.connector}`}
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
        if (keyval === Gdk.KEY_Escape) App.get_window(`media-${monitor.connector}`)?.set_visible(false)
      }}
    >
      <box
        cssClasses={["popover-body"]}
        orientation={Gtk.Orientation.VERTICAL}
        spacing={16}
        widthRequest={360}
        hexpand={false}
        halign={Gtk.Align.END}
      >
        <label cssClasses={["popover-title"]} label="Media" xalign={0} />

        {/* MPRIS players — reactive to add/remove, deduped */}
        <box orientation={Gtk.Orientation.VERTICAL} spacing={12}>
          {bind(mpris, "players").as((players) => {
            const uniq = dedupePlayers(players)
            return uniq.length === 0
              ? (<label cssClasses={["hint"]} label="Nothing playing" xalign={0} />)
              : uniq.map((p) => <PlayerCard player={p} />)
          })}
        </box>

        <box cssClasses={["divider"]} heightRequest={1} />

        {/* Speaker */}
        <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
          <label cssClasses={["section-label"]} label="Speaker" xalign={0} />
          {wp?.audio?.defaultSpeaker && (
            <EndpointRow label="Speaker" endpoint={wp.audio.defaultSpeaker} />
          )}
        </box>

        {/* Microphone */}
        <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
          <label cssClasses={["section-label"]} label="Microphone" xalign={0} />
          {wp?.audio?.defaultMicrophone && (
            <EndpointRow label="Mic" endpoint={wp.audio.defaultMicrophone} />
          )}
        </box>

        <label cssClasses={["hint"]} label="Esc closes" xalign={1} />
      </box>
    </window>
  )
}
