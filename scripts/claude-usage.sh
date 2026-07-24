#!/usr/bin/env bash
# Waybar module: your REAL Claude plan usage, captured from Claude Code's
# statusline hook (see claude-statusline.sh) into ~/.cache/claude-usage.json.
# Headline is the 5-hour rolling window %, with the 7-day (weekly) % alongside.
#
# The number is only live while Claude Code is running - the hook updates the
# state file on each statusline tick. Between sessions it goes stale, so once a
# window's reset time has passed the value can't be trusted; we dim the module
# (class "stale") and say so in the tooltip rather than showing a bogus %.
set -uo pipefail

ICON="󰚩"
STATE="$HOME/.cache/claude-usage.json"

emit() {  # text, tooltip, class
  jq -cn --arg t "$1" --arg tt "$2" --arg c "$3" '{text: $t, tooltip: $tt, class: $c}'
}

if [ ! -f "$STATE" ]; then
  emit "$ICON  –" "No plan-usage data yet.\nRun Claude Code (Pro/Max) - the meter appears after the first reply." "stale"
  exit 0
fi

now=$(date +%s)
# Join with "|" (non-whitespace) so empty fields survive `read` - a tab
# delimiter is IFS-whitespace and collapses empty leading fields together.
IFS='|' read -r fh_pct fh_reset sd_pct sd_reset cap < <(
  jq -r '[
    (.five_hour.used_percentage  // ""),
    (.five_hour.resets_at         // ""),
    (.seven_day.used_percentage  // ""),
    (.seven_day.resets_at         // ""),
    (.captured_at                 // 0)
  ] | map(tostring) | join("|")' "$STATE"
)

if [ -z "$fh_pct" ] && [ -z "$sd_pct" ]; then
  emit "$ICON  –" "Waiting for the plan meter.\nIt populates after the first API response in a Claude Code session." "stale"
  exit 0
fi

round() { printf '%.0f' "$1"; }
at() { [ -n "$1" ] && date -d "@$1" +"$2" || echo "?"; }

# Stale once the captured 5h window has already reset (value no longer current).
class="fresh"
if [ -n "$fh_reset" ] && [ "$now" -ge "$fh_reset" ]; then
  class="stale"
fi

# Headline is the 5h session % only, to keep the bar clean; weekly is in the tooltip.
text="$ICON  $(round "${fh_pct:-0}")%"

tooltip=$(printf '5h window  %s%%  resets %s\nweekly     %s%%  resets %s\nofficial · captured %s%s' \
  "$(round "${fh_pct:-0}")" "$(at "$fh_reset" '%H:%M')" \
  "$(round "${sd_pct:-0}")" "$(at "$sd_reset" '%a %H:%M')" \
  "$(at "$cap" '%H:%M')" \
  "$([ "$class" = stale ] && echo ' · STALE (rerun Claude Code to refresh)' || echo ' · live')")

emit "$text" "$tooltip" "$class"
