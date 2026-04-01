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

### Ghostty (`app-configs/ghostty.nix`)
- Theme name must match exactly as listed by `ghostty +list-themes` (e.g. `"Gruvbox Dark"` with a space)
