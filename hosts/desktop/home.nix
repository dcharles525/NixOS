{ config, pkgs, ... }:

{
  #
  # Base Home Manager Configuration
  #

  home.username = "d";
  home.homeDirectory = "/home/d";
  programs.home-manager.enable = true;
  home.sessionVariables = {
    EDITOR = "vim";
  };
  home.stateVersion = "24.11";

  home.file.".config/rofi/config.rasi".text = ''
    @import "${pkgs.rofi-unwrapped}/share/rofi/themes/gruvbox-dark-soft.rasi"
  '';

  services.udiskie = {
    enable = true;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  home.pointerCursor = {
    enable = true;
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 24;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    cursorTheme = {
      package = pkgs.catppuccin-cursors.mochaDark;
      name = "pkgs.catppuccin-cursors.mochaDark";
    };
  };

  #
  # Theming
  #

  programs.ghostty.enable = true;
  programs.ghostty = {
    settings = {
      theme = "GruvboxDark";
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      monitor = DP-1, 2560x1440@60, 0x0, 1
      monitor = HDMI-A-1, 2560x1440@60, 2560x0, 1, transform, 3

      $terminal = ghostty
      $fileManager = dolphin
      $menu = wofi --show drun

      exec-once = waybar
      exec-once=sleep 5 && hyprpaper &

      cursor {
        enable_hyprcursor = false
      }

      env = XCURSOR_THEME,Whiteglass
      env = XCURSOR_SIZE,24
      #env = HYPRCURSOR_SIZE,24

      general {
        gaps_in = 5
        gaps_out = 10

        border_size = 2

        col.active_border = rgba(FFD865ee)
        col.inactive_border = rgba(595959aa)

        resize_on_border = false

        allow_tearing = false

        layout = dwindle
      }

      decoration {
        rounding = 5

        active_opacity = 1.0
        inactive_opacity = 1.0

        shadow {
          enabled = true
          range = 4
          render_power = 3
          color = rgba(1a1a1aee)
        }

        blur {
          enabled = true
          size = 3
          passes = 1

          vibrancy = 0.1696
        }
      }

      animations {
        enabled = yes, please :)

        bezier = easeOutQuint,0.23,1,0.32,1
        bezier = easeInOutCubic,0.65,0.05,0.36,1
        bezier = linear,0,0,1,1
        bezier = almostLinear,0.5,0.5,0.75,1.0
        bezier = quick,0.15,0,0.1,1

        animation = global, 1, 10, default
        animation = border, 1, 5.39, easeOutQuint
        animation = windows, 1, 4.79, easeOutQuint
        animation = windowsIn, 1, 4.1, easeOutQuint, popin 87%
        animation = windowsOut, 1, 1.49, linear, popin 87%
        animation = fadeIn, 1, 1.73, almostLinear
        animation = fadeOut, 1, 1.46, almostLinear
        animation = fade, 1, 3.03, quick
        animation = layers, 1, 3.81, easeOutQuint
        animation = layersIn, 1, 4, easeOutQuint, fade
        animation = layersOut, 1, 1.5, linear, fade
        animation = fadeLayersIn, 1, 1.79, almostLinear
        animation = fadeLayersOut, 1, 1.39, almostLinear
        animation = workspaces, 1, 1.94, almostLinear, fade
        animation = workspacesIn, 1, 1.21, almostLinear, fade
        animation = workspacesOut, 1, 1.94, almostLinear, fade
      }

      dwindle {
        pseudotile = true
        preserve_split = true # You probably want this
      }

      master {
        new_status = master
      }

      misc {
        force_default_wallpaper = -1
        disable_hyprland_logo = true
      }

      input {
        kb_layout = us
        kb_variant =
        kb_model =
        kb_options =
        kb_rules =

        follow_mouse = 1

        sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

        touchpad {
          natural_scroll = true
        }
      }

      gestures {
        workspace_swipe = false
      }

      device {
        name = epic-mouse-v1
        sensitivity = -0.5
      }

      $mainMod = SUPER # Sets "Windows" key as main modifier

      # Screenshot a window
      bind = $mainMod, PRINT, exec, hyprshot -m window
      # Screenshot a monitor
      bind = , PRINT, exec, hyprshot -m output
      # Screenshot a region
      bind = $shiftMod, PRINT, exec, hyprshot -m region

      bind = $mainMod, Q, exec, $terminal
      bind = $mainMod, C, killactive,
      bind = $mainMod, M, exit,
      bind = $mainMod, E, exec, $fileManager
      bind = $mainMod, V, togglefloating,
      bind = $mainMod, R, exec, $menu
      bind = $mainMod, P, pseudo, # dwindle
      bind = $mainMod, J, togglesplit, # dwindle
      bind = $mainMod, L, exec, hyprlock
      bind = $mainMod, N, exec, iwmenu -l rofi

      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d

      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10

      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10

      bind = $mainMod SHIFT, L, moveactive, 30 0
      bind = $mainMod SHIFT, H, moveactive, -30 0
      bind = $mainMod SHIFT, K, moveactive, 0 -30
      bind = $mainMod SHIFT, J, moveactive, 0 30

      bind = $mainMod, S, togglespecialworkspace, magic
      bind = $mainMod SHIFT, S, movetoworkspace, special:magic

      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1

      bind = $mainMod, S, exec, rofi -show drun -show-icons

      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow

      bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindel = ,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindel = ,XF86MonBrightnessUp, exec, brightnessctl s 10%+
      bindel = ,XF86MonBrightnessDown, exec, brightnessctl s 10%-

      bindl = , XF86AudioNext, exec, playerctl next
      bindl = , XF86AudioPause, exec, playerctl play-pause
      bindl = , XF86AudioPlay, exec, playerctl play-pause
      bindl = , XF86AudioPrev, exec, playerctl previous

      windowrulev2 = suppressevent maximize, class:.*

      windowrulev2 = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0
    '';
  };

  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      # BACKGROUND
      background {
        monitor =
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
          size = 250, 60
          outline_thickness = 2
          dots_size = 0.2 # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.35 # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = true
          outer_color = rgba(0, 0, 0, 0)
          inner_color = rgba(0, 0, 0, 0.2)
          font_color = rgba(255,255,255,1)
          fade_on_empty = false
          rounding = -1
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
    '';
  };

  services.hyprpaper.enable = true;
  services.hyprpaper.settings = {
    ipc = "on";
    splash = false;
    splash_offset = 2.0;

    preload = [ "~/Pictures/background.jpg" ];

    wallpaper = [
      "eDP-1,~/Pictures/background.jpg"
      "HDMI-A-1,~/Pictures/background.jpg"
      "DP-1,~/Pictures/background.jpg"
    ];
  };

  services.hypridle.enable = true;
  services.hypridle.settings = {
    general = {
      lock_cmd = "hyprlock";
      before_sleep_cmd = "hyprlock";
      after_sleep_cmd = "sleep 0.5 && hyprctl dispatch dpms on";
    };
    listener = [
      {
        timeout = 150;
        on-timeout = "brightnessctl -s set 10";
        on-resume = "brightnessctl -r";
      }
      {
        timeout = 150;
        on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
        on-resume = "brightnessctl -rd rgb:kbd_backlight";
      }
      {
        timeout = 300;
        on-timeout = "loginctl lock-session";
      }
      {
        timeout = 330;
        on-timeout = "hyprctl dispatch dpms off";
        on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
      }
      {
        timeout = 1800;
        on-timeout = "systemctl suspend";
      }
    ];
  };
  

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
          "battery#bat2"
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
        "custom/disks" = {
          format = "🖴 {}";
          interval = 2;
          exec = "iostat -dx 1 2 nvme1n1 | grep nvme1n1 | tail -1 | awk '{print $22\"%\"}'";
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

      #custom-disk {
        background-color: #1e1e2e;
        color: #cdd6f4;
      }
    '';
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        browser = "${config.programs.firefox.package}/bin/firefox -new-tab";
        dmenu = "${pkgs.rofi}/bin/rofi -dmenu";
        follow = "mouse";
        font = "Droid Sans 10";
        format = "<b>%s</b>\\n%b";
        frame_color = "#555555";
        frame_width = 2;
        geometry = "500x5-5+30";
        horizontal_padding = 8;
        icon_position = "off";
        line_height = 0;
        markup = "full";
        padding = 8;
        separator_color = "frame";
        separator_height = 2;
        transparency = 10;
        word_wrap = true;
        corner_radius = 10;
      };

      urgency_low = {
        background = "#1d1f21";
        foreground = "#4da1af";
        frame_color = "#4da1af";
        timeout = 10;
      };

      urgency_normal = {
        background = "#1d1f21";
        foreground = "#70a040";
        frame_color = "#70a040";
        timeout = 15;
      };

      urgency_critical = {
        background = "#1d1f21";
        foreground = "#dd5633";
        frame_color = "#dd5633";
        timeout = 0;
      };

      shortcuts = {
        context = "mod4+grave";
        close = "mod4+shift+space";
      };
    };
  };
}
