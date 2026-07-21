{ config, ... }:
{
  # Global Claude Code user settings. Managed here so every host gets the
  # statusline usage-monitor wiring (and model/effort defaults) on first
  # rebuild. Dynamic, per-machine state (permission grants) still lives in the
  # unmanaged ~/.claude/settings.local.json, so this file staying read-only is
  # fine. The statusLine command feeds ~/.cache/claude-usage.json, which the
  # waybar custom/claude module reads (see scripts/claude-{statusline,usage}.sh).
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
      }
    }
  '';
}
