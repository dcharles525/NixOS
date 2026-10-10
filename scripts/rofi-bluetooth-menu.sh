#!/usr/bin/env bash
#
# Rofi bluetooth menu.
#
# Uses `bluetoothctl <<< 'cmd'` (stdin form) for every read — on bluez 5.86
# the one-shot form `bluetoothctl <cmd>` returns empty for `devices`, `show`,
# and `info`, which silently breaks argument-mode helper scripts.
#
# The menu opens instantly from cached state; "Scan for devices" runs a
# blocking 10s scan then re-renders. No auto-scan, no notifications — the
# whole flow stays inside rofi.

ROFI="rofi -dmenu"

# Strip ANSI colour codes + interactive noise from bluetoothctl output.
bt_read() {
    bluetoothctl <<< "$1" 2>/dev/null \
        | sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g' \
        | grep -Ev '^\[bluetoothctl\]>|^Waiting to connect|^Agent registered|^\[CHG\]|^\[NEW\]|^\[DEL\]'
}

power_on()        { bt_read "show" | grep -qE '^[[:space:]]+Powered: yes'; }
scan_on()         { bt_read "show" | grep -qE '^[[:space:]]+Discovering: yes'; }
pairable_on()     { bt_read "show" | grep -qE '^[[:space:]]+Pairable: yes'; }
discoverable_on() { bt_read "show" | grep -qE '^[[:space:]]+Discoverable: yes'; }

# $1 = mac, $2 = field
device_field() {
    bt_read "info $1" | awk -F': ' -v f="$2" '$1 ~ ("^[[:space:]]+" f "$") {print $2}' | head -1
}
device_connected() { [ "$(device_field "$1" Connected)" = "yes" ]; }
device_paired()    { [ "$(device_field "$1" Paired)" = "yes" ]; }
device_trusted()   { [ "$(device_field "$1" Trusted)" = "yes" ]; }

# Emits: MAC<TAB>Name  (one per line)
list_devices() {
    bt_read "devices" | awk '/^Device / {mac=$2; $1=$2=""; sub(/^ +/, ""); print mac"\t"$0}'
}

show_menu() {
    if ! power_on; then
        choice=$(printf "Power on\nExit" | $ROFI -p "Bluetooth (off)")
        case "$choice" in
            "Power on") bluetoothctl power on >/dev/null; show_menu ;;
            *) exit 0 ;;
        esac
        return
    fi

    devices_out=$(list_devices)

    device_lines=""
    while IFS=$'\t' read -r mac name; do
        [ -z "$mac" ] && continue
        flag=""
        device_connected "$mac" && flag=" [connected]"
        device_lines+="${name}${flag}"$'\n'
    done <<< "$devices_out"

    scan_state=$(scan_on         && echo "Scan: on"         || echo "Scan: off")
    pair_state=$(pairable_on     && echo "Pairable: on"     || echo "Pairable: off")
    disc_state=$(discoverable_on && echo "Discoverable: on" || echo "Discoverable: off")

    # Devices first, then divider, then actions.
    menu="${device_lines}---
Scan for devices
Power off
$scan_state
$pair_state
$disc_state
Exit"

    choice=$(printf "%s" "$menu" | $ROFI -p "Bluetooth")

    case "$choice" in
        ""|"---") exit 0 ;;
        "Scan for devices")
            # Blocking scan; rofi reopens with the fresh list.
            bluetoothctl --timeout 10 scan on >/dev/null 2>&1
            show_menu
            ;;
        "Power off")     bluetoothctl power off >/dev/null; exit 0 ;;
        "Scan: on")      bluetoothctl scan off >/dev/null; show_menu ;;
        "Scan: off")     bluetoothctl --timeout 10 scan on >/dev/null 2>&1 & show_menu ;;
        "Pairable: on")  bluetoothctl pairable off >/dev/null; show_menu ;;
        "Pairable: off") bluetoothctl pairable on  >/dev/null; show_menu ;;
        "Discoverable: on")  bluetoothctl discoverable off >/dev/null; show_menu ;;
        "Discoverable: off") bluetoothctl discoverable on  >/dev/null; show_menu ;;
        *)
            # Strip trailing " [connected]" tag to recover the raw name.
            name="${choice% \[connected\]}"
            mac=$(awk -F'\t' -v n="$name" '$2 == n {print $1; exit}' <<< "$devices_out")
            [ -z "$mac" ] && exit 0
            device_menu "$mac" "$name"
            ;;
    esac
}

device_menu() {
    local mac=$1 name=$2
    local conn paired trusted
    conn=$(device_connected "$mac" && echo "Connected: yes" || echo "Connected: no")
    paired=$(device_paired  "$mac" && echo "Paired: yes"    || echo "Paired: no")
    trusted=$(device_trusted "$mac" && echo "Trusted: yes"  || echo "Trusted: no")

    choice=$(printf "%s\n%s\n%s\nBack\nExit" "$conn" "$paired" "$trusted" | $ROFI -p "$name")

    case "$choice" in
        "$conn")
            if device_connected "$mac"; then
                bluetoothctl disconnect "$mac" >/dev/null
            else
                # Trust before connect so bluez skips the auth agent prompt on
                # devices that were paired manually but never trusted.
                bt_pair_connect "$mac"
            fi
            device_menu "$mac" "$name"
            ;;
        "$paired")
            if device_paired "$mac"; then
                bluetoothctl remove "$mac" >/dev/null
                show_menu
            else
                bt_pair_connect "$mac"
                device_menu "$mac" "$name"
            fi
            ;;
        "$trusted")
            if device_trusted "$mac"; then bluetoothctl untrust "$mac" >/dev/null
            else bluetoothctl trust "$mac" >/dev/null; fi
            device_menu "$mac" "$name"
            ;;
        "Back") show_menu ;;
        *)      exit 0 ;;
    esac
}

# Full pair-and-connect flow in a single bluetoothctl session.
#
# bluetoothctl exits when stdin closes, so a plain heredoc dispatches `pair` /
# `connect` and then EOFs before the async operations complete. Piping via a
# subshell with `sleep` between the commands holds the REPL open long enough
# for the SSP passkey confirm (auto-answered by NoInputNoOutput agent) and
# the pair/connect round-trips to finish.
bt_pair_connect() {
    local mac=$1
    local log=/tmp/bt-pair.log
    {
        echo "=== $(date -Iseconds) pair+connect $mac ==="
        {
            echo "agent NoInputNoOutput"
            echo "default-agent"
            echo "trust $mac"
            echo "pair $mac"
            # Nothing (and other SSP "Numeric Comparison" devices) prompt
            # 'Confirm passkey (yes/no):' even under NoInputNoOutput. Queue
            # a yes so bluetoothctl's next stdin read answers it. Multiple
            # yeses are cheap — bluetoothctl treats stray ones as unknown
            # commands and continues.
            sleep 4
            echo "yes"
            sleep 2
            echo "yes"
            sleep 8
            echo "connect $mac"
            sleep 8
        } | bluetoothctl 2>&1 | sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g'
        echo "=== end ==="
    } >> "$log"
}

# Optional --status hook (waybar custom module etc.)
print_status() {
    if power_on; then
        printf ""
        list_devices | while IFS=$'\t' read -r mac name; do
            device_connected "$mac" && printf " %s" "$name"
        done
        printf "\n"
    else
        echo ""
    fi
}

case "$1" in
    --status) print_status ;;
    *)        show_menu ;;
esac
