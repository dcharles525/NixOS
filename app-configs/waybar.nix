{ config, ... }:
{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 43;
        spacing = 4;
        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [
          "hyprland/window"
        ];
        modules-right = [
          "pulseaudio"
          "network"
          "bluetooth"
          "cpu"
          "memory"
          "custom/disks"
          "temperature"
          "battery"
          "custom/power-profile"
          "clock"
          "custom/suspend"
          "custom/poweroff"
        ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          warp-on-scroll = false;
          format = "{name}";
          format-icons = {
            urgent = "";
            active = "";
            default = "";
          };
        };
        
        "pulseaudio" = {
          format = "{icon}  {volume}%";
          format-bluetooth = "{icon} {volume}%  {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = " {volume}%";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          on-click = "${config.home.homeDirectory}/NixOS/scripts/rofi-sound-picker.sh";
        };

        "network" = {
          format-wifi = "   {essid} ({signalStrength}%)";
          format-ethernet = "Ethernet ";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          on-click = "${config.home.homeDirectory}/NixOS/scripts/rofi-wifi-menu.sh";
        };
        "bluetooth" = {
          format = " {status}";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "${config.home.homeDirectory}/NixOS/scripts/rofi-bluetooth-menu.sh";
        };
        "cpu" = {
            format = "  {usage}%";
            tooltip = true;
        };
        "memory" = {
            format = "  {}%";
            tooltip = true;
        };
        "temperature" = {
            interval = 10;
            hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
            input-filename = "temp1_input";
            critical-threshold = 100;
            format-critical = " {temperatureF}";
            format = " {temperatureF}°F";
        };
        "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon}  {capacity}%";
            format-full = "{icon}  {capacity}%";
            format-charging =  "  {capacity}%";
            format-plugged = "  {capacity}%";
            format-alt = "{time}  {icon}";
            format-icons = ["" "" "" "" ""];
        };
        "clock" = {
          format = "{:%H:%M | %e %B} ";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };
        "custom/suspend" = {
          format = "⏾";
          tooltip-format = "Sleeply Time";
          on-click = "hyprlock & sleep 1; systemctl suspend";
        };
        "custom/poweroff" = {
          format = "⏻ ";
          tooltip-format = "Darkness";
          on-click = "exec systemctl poweroff";
        };
        "custom/power-profile" = {
          exec = "${config.home.homeDirectory}/.config/waybar/scripts/power-profile.sh get";
          on-click = "${config.home.homeDirectory}/.config/waybar/scripts/power-profile.sh toggle";
          interval = 1;
          format = "{}";
          tooltip = true;
          tooltip-format = "Power Profile: {}";
        };
        "custom/disks" = {
          format = "🖴 {}";
          interval = 2;
          exec = "iostat -dx 1 2 nvme0n1 | grep nvme0n1 | tail -1 | awk '{print $22\"%\"}'";
        };
      };
    };
    style = ''
      * {
        font-family: "Fira Sans Semibold", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
        font-size: 15px;
        transition: background-color .3s ease-out;
      }

      window#waybar {
        background: transparent;
        color: #FFC519;
        font-family:
          SpaceMono Nerd Font,
          feather;
        transition: background-color .5s;
      }

      .modules-left,
      .modules-center,
      .modules-right {
        background: rgba(0, 0, 8, .7);
        margin: 5px 5px;
        border-radius: 15px;
      }

      .modules-left {
        padding: 0;
      }

      .modules-center,
      .modules-right {
        padding: 5px 10px;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #backlight,
      #network,
      #bluetooth,
      #pulseaudio,
      #wireplumber,
      #custom-media,
      #tray,
      #mode,
      #idle_inhibitor,
      #scratchpad,
      #power-profiles-daemon,
      #language,
      #custom-poweroff,
      #custom-suspend,
      #custom-disks,
      #mpd {
        padding: 2px 10px;
        border-radius: 15px;
      }

      #clock:hover,
      #battery:hover,
      #bluetooth:hover,
      #cpu:hover,
      #memory:hover,
      #disk:hover,
      #temperature:hover,
      #backlight:hover,
      #network:hover,
      #pulseaudio:hover,
      #wireplumber:hover,
      #custom-media:hover,
      #tray:hover,
      #mode:hover,
      #idle_inhibitor:hover,
      #scratchpad:hover,
      #power-profiles-daemon:hover,
      #language:hover,
      #mpd:hover {
        background: rgba(26, 27, 38, 0.9);
      }

      #workspaces button {
        background: transparent;
        font-family:
          SpaceMono Nerd Font,
          feather;
        font-weight: 900;
        font-size: 13pt;
        color: #FFC519;
        border:none;
        border-radius: 15px;
      }

      #workspaces button.active {
        background: #13131d;
      }

      #workspaces button:hover {
        background: #11111b;
        color: #FFC519;
        box-shadow: none;
      }

    '';
  };

  home.file.".config/waybar/scripts/power-profile.sh" = {
    text = ''
      #!/usr/bin/env bash

      # Get current power profile
      get_profile() {
          powerprofilesctl get
      }

      # Get icon based on profile
      get_icon() {
          case "$(get_profile)" in
              "power-saver")
                  echo "󰌪"  # battery icon
                  ;;
              "balanced")
                  echo "󰗑"  # balanced icon
                  ;;
              "performance")
                  echo "󱐋"  # performance icon
                  ;;
              *)
                  echo "󰚥"  # unknown
                  ;;
          esac
      }

      # Toggle to next profile
      toggle_profile() {
          current=$(get_profile)
          case "$current" in
              "power-saver")
                  powerprofilesctl set balanced
                  ;;
              "balanced")
                  powerprofilesctl set performance
                  ;;
              "performance")
                  powerprofilesctl set power-saver
                  ;;
          esac
      }

      # Main logic
      case "$1" in
          "toggle")
              toggle_profile
              ;;
          "get")
              profile=$(get_profile)
              # Capitalize first letter of each word
              capitalized=$(echo "$profile" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
              echo "$(get_icon) $capitalized"
              ;;
          *)
              profile=$(get_profile)
              # Capitalize first letter of each word
              capitalized=$(echo "$profile" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
              echo "$(get_icon) $capitalized"
              ;;
      esac
    '';
    executable = true;
  };
}
