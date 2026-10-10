{ config, pkgs, ... }:
let
  # ags 2.x (Astal-based). extraPackages populates the runtime GI_TYPELIB_PATH
  # + Node/import resolution so `astal/*` module imports and `astal-*` gir
  # types are available. Start minimal; add libs as new popovers are written.
  agsPkg = pkgs.ags.override {
    extraPackages = [
      # GTK4 + layer-shell typelibs. Ags's wrapper only inherits GI_TYPELIB_PATH
      # from packages listed here — astal4 alone isn't enough because it needs
      # Gdk-4.0/Gtk-4.0 (from gtk4) and Astal.Window layer-shell support.
      pkgs.gtk4
      pkgs.gtk4-layer-shell
    ] ++ (with pkgs.astal; [
      astal4
      io
      gjs
      wireplumber    # audio (Media popover)
      mpris          # media playback (Media popover)
      bluetooth      # BT devices + scan (Bluetooth popover)
      # Wifi popover uses `iw` + `ip` + `rfkill` via execAsync + iwgtk for
      # network management — no astal.network needed (that lib is NM-only).
      # Reserved for future popovers:
      # hyprland
      # tray
    ]);
  };
in
{
  home.packages = [ agsPkg ];

  # Ship the AGS source directory into ~/.config/ags as a symlink; ags reads
  # from XDG_CONFIG_HOME/ags by default. Read-only via /nix/store, but edits
  # to the file in this repo + nixos-rebuild switch update the symlink.
  xdg.configFile.ags = {
    source = ./ags;
    recursive = true;
  };

  # Long-running GJS process — keep it alive across the whole graphical
  # session and restart on crash. Waybar/Hyprland speak to it via
  # `ags request '...'`.
  systemd.user.services.ags = {
    Unit = {
      Description = "AGS widget shell (Astal)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      # --gtk4 is REQUIRED — it LD_PRELOADs libgtk4-layer-shell.so. Without
      # it, Astal.Window falls back to plain Gtk.Window and Hyprland tiles
      # our popovers as regular app windows instead of overlaying them.
      ExecStart = "${agsPkg}/bin/ags run --gtk4";
      Restart = "on-failure";
      RestartSec = "3";
      # gjs looks up type libs by GI_TYPELIB_PATH; nix's wrapper on the
      # ags binary already sets these, no extra Environment= needed.
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
