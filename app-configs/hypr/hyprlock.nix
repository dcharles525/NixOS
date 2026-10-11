{ pkgs, specialArgs, ... }:
let
  # MGX palette, generated from llm-skills/design/tokens.css.
  mgx = (import ../mgx.nix).dark;
  background = builtins.path { path = ../../assets/background.jpg; name = "background.jpg"; };
  # nixpkgs hyprlock (v0.9.6) patched to survive TC1/Thunderbolt link-training
  # output removal during an active session lock. See hyprlock-tc1.patch for
  # the full rationale.
  hyprlock-pkg = pkgs.hyprlock.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./hyprlock-tc1.patch ];
  });
in
{
  systemd.user.services.hyprlock = {
    Unit = {
      Description = "Hyprlock screen locker";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${hyprlock-pkg}/bin/hyprlock";
      Restart = "on-failure";
      RestartSec = "5";
    };
  };

  programs.hyprlock = {
    package = hyprlock-pkg;
    enable = true;
    extraConfig = ''
      # GENERAL
      general {
          hide_cursor = false
          ignore_empty_input = true
      }

      # BACKGROUND
      background {
        monitor =
        path = ${background}
        blur_passes = 2
      }

      # INPUT FIELD
      input-field {
          monitor =
          size = 350, 60
          # MGX: a stadium outline, ink dots on black.
          outline_thickness = 1
          dots_size = 0.2
          dots_spacing = 0.35
          dots_center = true
          outer_color = rgb(${mgx.ink})
          inner_color = rgba(${mgx.bg}d9)
          font_color = rgb(${mgx.ink})
          fade_on_empty = false
          rounding = -1
          check_color = rgb(${mgx.warn})
          fail_color = rgb(${mgx.alert})
          placeholder_text = <span foreground="##${mgx.inkDim}">INPUT : PASSWORD_</span>
          hide_input = false
          position = 0, -200
          halign = center
          valign = center
      }

      # DATE
      label {
        monitor =
        text = cmd[update:1000] echo "$(date +"%A // %B %d" | tr a-z A-Z)"
        color = rgb(${mgx.inkDim})
        font_size = 16
        font_family = JetBrainsMono Nerd Font
        position = 0, 300
        halign = center
        valign = center
      }

      # TIME
      label {
        monitor =
        text = cmd[update:1000] echo "$(date +"%-I:%M")"
        color = rgb(${mgx.ink})
        font_size = 110
        font_family = JetBrainsMono Nerd Font ExtraLight
        position = 0, 200
        halign = center
        valign = center
      }

      # SLEEP BUTTON BG
      shape {
        monitor =
        size = 46, 46
        color = rgba(${mgx.bg}d9)
        rounding = -1
        border_size = 1
        border_color = rgb(${mgx.ink})
        position = -34, -290
        halign = center
        valign = center
      }

      # SLEEP BUTTON ICON
      label {
        monitor =
        text = 󰒲
        color = rgb(${mgx.ink})
        font_size = 18
        font_family = Symbols Nerd Font
        position = -34, -290
        halign = center
        valign = center
        onclick = systemctl ${if specialArgs.host == "desktop" then "hibernate" else "suspend"}
      }

      # SHUTDOWN BUTTON BG
      shape {
        monitor =
        size = 46, 46
        color = rgba(${mgx.bg}d9)
        rounding = -1
        border_size = 1
        border_color = rgb(${mgx.ink})
        position = 34, -290
        halign = center
        valign = center
      }

      # SHUTDOWN BUTTON ICON
      label {
        monitor =
        text = 󰐥
        color = rgb(${mgx.ink})
        font_size = 18
        font_family = Symbols Nerd Font
        position = 34, -290
        halign = center
        valign = center
        onclick = systemctl poweroff
      }
    '';
  };
}
