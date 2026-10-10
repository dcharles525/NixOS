{ config, ... }:
{
  # Global Claude Code user settings. Managed here so every host gets the
  # statusline usage-monitor wiring (and model/effort defaults) on first
  # rebuild. Dynamic, per-machine state (permission grants) still lives in the
  # unmanaged ~/.claude/settings.local.json, so this file staying read-only is
  # fine. The statusLine command feeds ~/.cache/claude-usage.json, which the
  # waybar custom/claude module reads (see scripts/claude-{statusline,usage}.sh).
  # hooks: copied from llm-skills/adapters/claude/hooks.settings.json. Every
  # event runs llm-skills/hooks/dispatch.py via the ~/.claude/llm-skills link
  # that llm-skills/tools/sync writes, so rule edits are live without a
  # rebuild. Only adding an event needs one. LLM_SKILLS_HOOKS=off disables all.
  home.file.".claude/settings.json".text = ''
    {
      "env": {
        "NODE_EXTRA_CA_CERTS": "${config.home.homeDirectory}/.claude/epinio-ca.crt"
      },
      "model": "opus[1m]",
      "effortLevel": "high",
      "tui": "default",
      "statusLine": {
        "type": "command",
        "command": "${config.home.homeDirectory}/NixOS/scripts/claude-statusline.sh",
        "padding": 2
      },
      "hooks": {
        "SessionStart": [
          {
            "hooks": [
              {
                "type": "command",
                "command": "f=\"$HOME/.claude/llm-skills/hooks/dispatch.py\"; [ -f \"$f\" ] || exit 0; exec python3 \"$f\" --harness claude --event SessionStart",
                "statusMessage": "Establishing session mode..."
              }
            ]
          }
        ],
        "UserPromptSubmit": [
          {
            "hooks": [
              {
                "type": "command",
                "command": "f=\"$HOME/.claude/llm-skills/hooks/dispatch.py\"; [ -f \"$f\" ] || exit 0; exec python3 \"$f\" --harness claude --event UserPromptSubmit",
                "statusMessage": "Checking skill routing..."
              }
            ]
          }
        ],
        "PreToolUse": [
          {
            "hooks": [
              {
                "type": "command",
                "command": "f=\"$HOME/.claude/llm-skills/hooks/dispatch.py\"; [ -f \"$f\" ] || exit 0; exec python3 \"$f\" --harness claude --event PreToolUse"
              }
            ]
          }
        ],
        "PostToolUse": [
          {
            "hooks": [
              {
                "type": "command",
                "command": "f=\"$HOME/.claude/llm-skills/hooks/dispatch.py\"; [ -f \"$f\" ] || exit 0; exec python3 \"$f\" --harness claude --event PostToolUse"
              }
            ]
          }
        ],
        "Stop": [
          {
            "hooks": [
              {
                "type": "command",
                "command": "f=\"$HOME/.claude/llm-skills/hooks/dispatch.py\"; [ -f \"$f\" ] || exit 0; exec python3 \"$f\" --harness claude --event Stop"
              }
            ]
          }
        ],
        "PreCompact": [
          {
            "hooks": [
              {
                "type": "command",
                "command": "f=\"$HOME/.claude/llm-skills/hooks/dispatch.py\"; [ -f \"$f\" ] || exit 0; exec python3 \"$f\" --harness claude --event PreCompact"
              }
            ]
          }
        ],
        "SessionEnd": [
          {
            "hooks": [
              {
                "type": "command",
                "command": "f=\"$HOME/.claude/llm-skills/hooks/dispatch.py\"; [ -f \"$f\" ] || exit 0; exec python3 \"$f\" --harness claude --event SessionEnd",
                "timeout": 5
              }
            ]
          }
        ]
      }
    }
  '';
}
