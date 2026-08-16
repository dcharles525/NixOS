#!/usr/bin/env bash

# Hide the waybar mic module when the default source is a monitor loopback
# (i.e. no real input hardware is active — happens on desktops with output-only DACs).

default=$(pactl get-default-source 2>/dev/null)
if [[ -z "$default" || "$default" == *.monitor ]]; then
    echo ""
    exit 0
fi

info=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
if [[ -z "$info" ]]; then
    echo ""
    exit 0
fi

# Nerd Font Awesome glyphs:  microphone,  microphone-slash.
# Written as raw UTF-8 bytes via \x escapes so the file stays ASCII.
if [[ "$info" == *"[MUTED]"* ]]; then
    printf "\xef\x84\xb1   Muted\n"
else
    printf "\xef\x84\xb0  %d%%\n" "$(awk '{printf "%d", $2*100}' <<<"$info")"
fi
