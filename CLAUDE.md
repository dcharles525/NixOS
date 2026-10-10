# NixOS Config — Claude Context

## Hosts
- **ktop** (`hosts/ktop/configuration.nix`) — primary desktop, currently in use
- **laptop** (`hosts/laptop/configuration.nix`)
- **desktop** (`hosts/desktop/configuration.nix`)

Home Manager config is in `home.nix`, app configs live under `app-configs/`.

## Key Notes

### Hyprland (`app-configs/hypr/hyprland.nix`)
- On Hyprland 0.54+, `windowrulev2` is deprecated. Replacement syntax:
  - `windowrule = suppress_event maximize, match:class .*`
  - `windowrule = no_focus on, match:class ^$, match:title ^$, match:xwayland 1, match:fullscreen 0`
  - Note: `floating` and `pinned` are not valid matchers in the new syntax
- `gestures { workspace_swipe }` no longer exists in 0.54+

### Audio (ktop)
- PipeWire + WirePlumber. Card: `alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic`
- Two UCM profiles: `HiFi (..., Speaker)` and `HiFi (..., Headphones)` — jack detection switches between them
- WirePlumber is configured with `api.acp.auto-profile = true` for this card so it auto-switches on headphone plug/unplug
- HDMI/DP sinks have `priority.session = 0` to prevent auto-switching to them when monitors connect
- If auto-switching breaks, check `~/.local/state/wireplumber/default-profile` — a stale stored profile will override auto-detection. Delete it and restart wireplumber: `systemctl --user restart wireplumber`
- Manual profile switch: `pactl set-card-profile alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)"`

### Waybar (`app-configs/waybar.nix`)
- Custom disk I/O indicator uses `iostat` on `nvme0n1` (not nvme1n1)
- Power profile script is at `.config/waybar/scripts/power-profile.sh`

### lazydocker over SSH (`hosts/ktop/configuration.nix`)
- `lazydocker-remote` runs lazydocker against a remote docker daemon. The nixpkgs
  build reads the docker context store but has no `ssh://` connection helper, so
  pointing it at an ssh context makes it speak HTTP at sshd and fail with
  `context deadline exceeded`. The wrapper forwards the remote socket over SSH
  and sets `DOCKER_HOST` instead.
- Target host defaults to the ssh alias `dockerhost` (defined in `~/.ssh/config`,
  not tracked here). Override with `LAZYDOCKER_REMOTE_HOST`.
- The forward must use `ControlPath=none`. With `ControlMaster` enabled for the
  host, `ssh -L` becomes a mux client, hands the forward to the master, and takes
  it back down when the short-lived client exits.
- The docker CLI is unaffected and works with a plain `ssh://` context.

### rpi-imager (`hosts/ktop/configuration.nix`)
- `rpi-imager` is overlaid with a launcher that runs it under `fakeroot`. The app
  hard-fails on a bare `geteuid() != 0` check, but `d` is in group `disk` and
  removable devices are 0660 root:disk, so the real I/O succeeds unprivileged.
  `fakeroot` satisfies only the check. Running under `sudo` cannot work: root has
  no session portal, so the file picker comes up empty.
- The launcher adds `--qml-file-dialogs` for the GUI only. rpi-imager's native
  picker filters to `*.img/zip/gz/xz/zst/wic` and hides `*.iso`. The `--cli`
  argument parser rejects the flag with `Unknown option`, so it must not be
  passed unconditionally.
- Hyprland ships no polkit agent, hence the `hyprpolkitagent` user service, and
  rpi-imager hardcodes `/usr/bin/pkexec`, hence the `systemd.tmpfiles` symlink to
  `/run/wrappers/bin/pkexec`.
- There can be only one `nixpkgs.overlays` assignment per module. Add new
  overlays to the existing list around line 294.

### Ghostty (`app-configs/ghostty.nix`)
- Theme name must match exactly as listed by `ghostty +list-themes` (e.g. `"Gruvbox Dark"` with a space)
