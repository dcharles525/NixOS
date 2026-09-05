{ config, pkgs, ... }:
{
  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "application";
      control-center-margin-top = 8;
      control-center-margin-bottom = 8;
      control-center-margin-right = 8;
      control-center-margin-left = 8;
      notification-2fa-action = true;
      notification-inline-replies = false;
      notification-icon-size = 48;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 0;
      fit-to-screen = false;
      control-center-width = 380;
      control-center-height = 640;
      notification-window-width = 360;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;

      widgets = [
        "title"
        "dnd"
        "mpris"
        "volume"
        "buttons-grid"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd = {
          text = "Do Not Disturb";
        };
        mpris = {
          image-size = 96;
          image-radius = 12;
        };
        volume = {
          label = "󰕾 ";
          show-per-app = true;
        };
        buttons-grid = {
          actions = [
            {
              label = "󰂯";
              command = "${pkgs.overskride}/bin/overskride";
            }
            {
              label = "󰖩";
              command = "${pkgs.iwgtk}/bin/iwgtk";
            }
            {
              label = "󰓃";
              command = "${pkgs.pwvucontrol}/bin/pwvucontrol";
            }
            {
              label = "󰤄";
              command = "systemctl hibernate";
            }
          ];
        };
      };
    };

    # Palette lifted 1:1 from rofi/waybar/dunst:
    #   bg          #000000a6  (translucent black, matches rofi window)
    #   fg          #f2f3f4    (near-white text)
    #   accent      #FFC519    (rofi border, waybar highlight)
    #   ok/normal   #70a040    (dunst normal urgency)
    #   info/low    #4da1af    (dunst low urgency)
    #   urgent      #dd5633    (dunst critical urgency)
    # 15px corner radius everywhere, 1px solid accent border on the shell.
    style = ''
      * {
        font-family: "JetBrains Mono", "Symbols Nerd Font", sans-serif;
        font-size: 13px;
        border: none;
        box-shadow: none;
      }

      .control-center {
        background: #000000a6;
        border: 1px solid #FFC519;
        border-radius: 15px;
        padding: 12px;
        margin: 8px;
        color: #f2f3f4;
      }

      .widget-title > label {
        color: #f2f3f4;
        font-size: 15px;
        font-weight: bold;
      }
      .widget-title > button {
        background: rgba(255, 255, 255, 0.06);
        color: #f2f3f4;
        border-radius: 10px;
        padding: 4px 10px;
        border: 1px solid #ffffff14;
      }
      .widget-title > button:hover {
        background: rgba(255, 255, 255, 0.10);
        color: #FFC519;
        border-color: #FFC519;
      }

      .widget-dnd {
        margin: 8px 0;
        color: #f2f3f4;
      }
      .widget-dnd > switch {
        background: rgba(255, 255, 255, 0.08);
        border-radius: 12px;
        border: 1px solid #ffffff14;
      }
      .widget-dnd > switch:checked {
        background: #dd5633;
        border-color: #dd5633;
      }

      .widget-mpris {
        color: #f2f3f4;
        margin: 8px 0;
        background: rgba(255, 255, 255, 0.04);
        border: 1px solid #ffffff14;
        border-radius: 12px;
        padding: 8px;
      }
      .widget-mpris-player {
        padding: 4px;
      }
      .widget-mpris-title {
        font-weight: bold;
        color: #FFC519;
      }
      .widget-mpris-subtitle {
        opacity: 0.75;
      }
      .widget-mpris button {
        background: transparent;
        color: #f2f3f4;
        border-radius: 8px;
        padding: 4px 8px;
      }
      .widget-mpris button:hover {
        background: rgba(255, 255, 255, 0.08);
        color: #FFC519;
      }

      .widget-volume {
        margin: 8px 0;
        color: #f2f3f4;
      }
      .widget-volume trough {
        min-height: 8px;
        background: rgba(255, 255, 255, 0.10);
        border-radius: 4px;
      }
      .widget-volume highlight {
        background: #FFC519;
        border-radius: 4px;
      }

      .widget-buttons-grid {
        margin: 8px 0;
        padding: 4px;
      }
      .widget-buttons-grid > flowbox > flowboxchild > button {
        background: rgba(255, 255, 255, 0.06);
        color: #f2f3f4;
        border: 1px solid #ffffff14;
        border-radius: 12px;
        min-height: 48px;
        min-width: 48px;
        font-size: 20px;
      }
      .widget-buttons-grid > flowbox > flowboxchild > button:hover {
        background: rgba(255, 255, 255, 0.10);
        color: #FFC519;
        border-color: #FFC519;
      }

      .notification-row {
        outline: none;
        margin: 6px 0;
      }
      .notification {
        background: rgba(0, 0, 0, 0.65);
        border-radius: 15px;
        margin: 0;
        padding: 0;
      }
      .notification-content {
        padding: 10px;
        color: #f2f3f4;
      }
      .notification.low      { border-left: 3px solid #4da1af; }
      .notification.normal   { border-left: 3px solid #70a040; }
      .notification.critical { border-left: 3px solid #dd5633; background: rgba(0, 0, 0, 0.85); }

      .notification-default-action, .notification-action {
        background: transparent;
        color: #f2f3f4;
        border-radius: 10px;
      }
      .notification-default-action:hover, .notification-action:hover {
        background: rgba(255, 255, 255, 0.08);
        color: #FFC519;
      }

      .close-button {
        background: rgba(255, 255, 255, 0.06);
        color: #f2f3f4;
        border: none;
        border-radius: 8px;
        min-width: 15px;
        min-height: 15px;
        padding: 1px 3px;
        margin-right: 15px;
        margin-top: 12px;
      }
      .close-button:hover {
        background: #dd5633;
        color: #f2f3f4;
      }

      /* Toast (floating) notifications outside the control center */
      .floating-notifications .notification {
        background: #000000a6;
        border: 1px solid #FFC519;
        border-radius: 15px;
        margin: 6px 10px;
      }
    '';
  };
}
