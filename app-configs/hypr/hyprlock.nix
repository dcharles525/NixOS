{ ... }:
let
  background = builtins.path { path = ../../assets/background.jpg; name = "background.jpg"; };
in
{
  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      # BACKGROUND
      background {
        monitor =
        path = ${background}
        blur_passes = 2
      }

      # GENERAL
      general {
          hide_cursor = false
          grace = 0
      }

      # INPUT FIELD
      input-field {
          monitor =
          size = 350, 60
          outline_thickness = 0
          dots_size = 0.2
          dots_spacing = 0.35
          dots_center = true
          outer_color = rgba(255, 255, 255, 0.15)
          inner_color = rgba(255, 255, 255, 0.1)
          font_color = rgba(255,255,255,1)
          fade_on_empty = false
          rounding = 15
          check_color = rgb(204, 136, 34)
          placeholder_text = <i><span foreground="##cdd6f4">Input Password...</span></i>
          hide_input = false
          position = 0, -200
          halign = center
          valign = center
      }

      # DATE
      label {
        monitor =
        text = cmd[update:1000] echo "$(date +"%A, %B %d")"
        color = rgba(242, 243, 244, 0.75)
        font_size = 22
        font_family = JetBrains Mono
        position = 0, 300
        halign = center
        valign = center
      }

      # TIME
      label {
        monitor =
        text = cmd[update:1000] echo "$(date +"%-I:%M")"
        color = rgba(242, 243, 244, 0.75)
        font_size = 95
        font_family = JetBrains Mono Extrabold
        position = 0, 200
        halign = center
        valign = center
      }

      # SLEEP BUTTON BG
      shape {
        monitor =
        size = 60, 60
        color = rgba(255, 255, 255, 0.1)
        rounding = 15
        border_size = 1
        border_color = rgba(255, 255, 255, 0.15)
        position = -50, -300
        halign = center
        valign = center
      }

      # SLEEP BUTTON ICON
      label {
        monitor =
        text = 󰒲
        color = rgba(242, 243, 244, 0.75)
        font_size = 24
        font_family = Symbols Nerd Font
        position = -50, -300
        halign = center
        valign = center
        onclick = systemctl suspend
      }

      # SHUTDOWN BUTTON BG
      shape {
        monitor =
        size = 60, 60
        color = rgba(255, 255, 255, 0.1)
        rounding = 15
        border_size = 1
        border_color = rgba(255, 255, 255, 0.15)
        position = 50, -300
        halign = center
        valign = center
      }

      # SHUTDOWN BUTTON ICON
      label {
        monitor =
        text = 󰐥
        color = rgba(242, 243, 244, 0.75)
        font_size = 24
        font_family = Symbols Nerd Font
        position = 50, -300
        halign = center
        valign = center
        onclick = systemctl poweroff
      }
    '';
  };
}
