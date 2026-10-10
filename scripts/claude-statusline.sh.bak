#!/usr/bin/env bash
# Claude Code statusline command. Claude Code pipes session JSON on stdin each
# time the statusline updates. We do two things with it:
#   1. Persist the OFFICIAL rate-limit meter to a state file, so the Waybar
#      module (claude-usage.sh) can show your real plan usage. rate_limits is
#      only present for Claude.ai Pro/Max, and only after the first API
#      response in a session - it's simply absent until then.
#   2. Print a status line for Claude Code's own bottom row.
# stdin JSON shape: https://code.claude.com/docs/en/statusline
set -uo pipefail

STATE="$HOME/.cache/claude-usage.json"
input=$(cat)
now=$(date +%s)

# Persist rate limits + session cost (atomic write). Nulls when absent.
if printf '%s' "$input" | jq -e . >/dev/null 2>&1; then
  printf '%s' "$input" | jq -c --argjson now "$now" '{
    captured_at: $now,
    five_hour:  (.rate_limits.five_hour  // null),
    seven_day:  (.rate_limits.seven_day  // null),
    cost_usd:   (.cost.total_cost_usd     // null)
  }' > "$STATE.tmp" 2>/dev/null && mv -f "$STATE.tmp" "$STATE"
fi

# Claude Code's own status line: model, context %, and the live plan meter.
printf '%s' "$input" | jq -r '
  "[\(.model.display_name)] \(.context_window.used_percentage // 0)% ctx"
  + (if .rate_limits.five_hour then "  ·  \(.rate_limits.five_hour.used_percentage | floor)% 5h" else "" end)
  + (if .rate_limits.seven_day then "  ·  \(.rate_limits.seven_day.used_percentage | floor)% wk" else "" end)
'
