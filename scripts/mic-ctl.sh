#!/usr/bin/env bash
#
# Waybar mic controller.
#
# Targets the mic source by NAME (via pactl) instead of setting it as the
# default source. Setting a bluez_input as default source triggers WirePlumber
# to switch the whole BT card to HSP/HFP mode, which tanks A2DP music quality.
# Read-only queries and direct set operations against the source name do NOT
# cause a profile switch — that only happens when a capture stream actually
# opens, or when a user explicitly sets it as default.
#
# Preference order: bluez_input.* > first non-monitor source > (hide).

pick_source() {
    pactl list short sources | awk '
        $2 ~ /^bluez_input\./         { bt = $2 }
        $2 !~ /\.monitor$/ && !real   { real = $2 }
        END { if (bt) print bt; else if (real) print real }
    '
}

action=${1:-status}
src=$(pick_source)

case "$action" in
    status)
        [ -z "$src" ] && exit 0
        muted=$(pactl get-source-mute "$src" 2>/dev/null | awk '{print $2}')
        if [ "$muted" = "yes" ]; then
            printf "\xef\x84\xb1   Muted\n"
        else
            vol=$(pactl get-source-volume "$src" 2>/dev/null \
                | head -1 | grep -oE '[0-9]+%' | head -1 | tr -d '%')
            printf "\xef\x84\xb0  %d%%\n" "${vol:-0}"
        fi
        ;;
    mute)
        [ -n "$src" ] && pactl set-source-mute "$src" toggle
        ;;
    vol-up)
        [ -n "$src" ] && pactl set-source-volume "$src" +5%
        ;;
    vol-down)
        [ -n "$src" ] && pactl set-source-volume "$src" -5%
        ;;
    *)
        echo "usage: $0 {status|mute|vol-up|vol-down}" >&2
        exit 2
        ;;
esac
