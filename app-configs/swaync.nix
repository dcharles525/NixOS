{ config, pkgs, ... }:
let
  # MGX palette, generated from llm-skills/design/tokens.css.
  mgx = (import ./mgx.nix).dark;
in
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

    # MGX: one ink on black, 1px hairlines, corners square or fully
    # round. Hover inverts. Hue only for urgency.
    style = ''
      * {
        font-family: "Chivo Mono", "JetBrainsMono Nerd Font",
          "Symbols Nerd Font", monospace;
        font-size: 13px;
        border: none;
        box-shadow: none;
      }

      .control-center {
        background: alpha(#${mgx.bg}, 0.92);
        border: 1px solid #${mgx.ink};
        border-radius: 0;
        padding: 12px;
        margin: 8px;
        color: #${mgx.ink};
      }

      .widget-title > label {
        color: #${mgx.ink};
        font-size: 15px;
        font-weight: 300;
        letter-spacing: 1px;
      }
      .widget-title > button {
        background: transparent;
        color: #${mgx.ink};
        border-radius: 999px;
        padding: 4px 10px;
        border: 1px solid #${mgx.lineStrong};
      }
      .widget-title > button:hover {
        background: #${mgx.ink};
        color: #${mgx.bg};
        border-color: #${mgx.ink};
      }

      .widget-dnd {
        margin: 8px 0;
        color: #${mgx.ink};
      }
      .widget-dnd > switch {
        background: transparent;
        border-radius: 999px;
        border: 1px solid #${mgx.lineStrong};
      }
      .widget-dnd > switch slider {
        background: #${mgx.ink};
        border-radius: 999px;
      }
      .widget-dnd > switch:checked {
        background: #${mgx.alert};
        border-color: #${mgx.alert};
      }
      .widget-dnd > switch:checked slider {
        background: #${mgx.bg};
      }

      .widget-mpris {
        color: #${mgx.ink};
        margin: 8px 0;
        background: transparent;
        border: 1px solid #${mgx.line};
        border-radius: 0;
        padding: 8px;
      }
      .widget-mpris-player {
        padding: 4px;
      }
      .widget-mpris-title {
        font-weight: 600;
        color: #${mgx.ink};
      }
      .widget-mpris-subtitle {
        color: #${mgx.inkDim};
      }
      .widget-mpris button {
        background: transparent;
        color: #${mgx.ink};
        border-radius: 999px;
        padding: 4px 8px;
      }
      .widget-mpris button:hover {
        background: #${mgx.ink};
        color: #${mgx.bg};
      }

      .widget-volume {
        margin: 8px 0;
        color: #${mgx.ink};
      }
      .widget-volume trough {
        min-height: 6px;
        background: #${mgx.line};
        border-radius: 0;
      }
      .widget-volume highlight {
        background: #${mgx.ink};
        border-radius: 0;
      }

      .widget-buttons-grid {
        margin: 8px 0;
        padding: 4px;
      }
      .widget-buttons-grid > flowbox > flowboxchild > button {
        background: transparent;
        color: #${mgx.ink};
        border: 1px solid #${mgx.lineStrong};
        border-radius: 999px;
        min-height: 34px;
        min-width: 34px;
        padding: 0;
      }
      /* The `*` rule pins every label to 13px, so size the glyph here. */
      .widget-buttons-grid > flowbox > flowboxchild > button label {
        font-size: 16px;
      }
      .widget-buttons-grid > flowbox > flowboxchild > button:hover {
        background: #${mgx.ink};
        color: #${mgx.bg};
        border-color: #${mgx.ink};
      }

      .notification-row {
        outline: none;
        margin: 6px 0;
      }
      .notification {
        background: alpha(#${mgx.bg}, 0.9);
        border: 1px solid #${mgx.line};
        border-radius: 0;
        margin: 0;
        padding: 0;
      }
      .notification-content {
        padding: 10px;
        color: #${mgx.ink};
      }
      .notification.low      { border-left: 3px solid #${mgx.inkFaint}; }
      .notification.normal   { border-left: 3px solid #${mgx.ink}; }
      .notification.critical {
        border-left: 3px solid #${mgx.alert};
        background: #${mgx.bg};
      }

      .notification-default-action, .notification-action {
        background: transparent;
        color: #${mgx.ink};
        border-radius: 999px;
      }
      .notification-default-action:hover, .notification-action:hover {
        background: #${mgx.bgRaised};
        color: #${mgx.ink};
      }

      .close-button {
        background: transparent;
        color: #${mgx.ink};
        border: 1px solid #${mgx.lineStrong};
        border-radius: 999px;
        min-width: 15px;
        min-height: 15px;
        padding: 1px 3px;
        margin-right: 15px;
        margin-top: 12px;
      }
      .close-button:hover {
        background: #${mgx.alert};
        border-color: #${mgx.alert};
        color: #${mgx.bg};
      }

      /* Toast (floating) notifications outside the control center */
      .floating-notifications .notification {
        background: alpha(#${mgx.bg}, 0.92);
        border: 1px solid #${mgx.ink};
        border-radius: 0;
        margin: 6px 10px;
      }
    '';
  };
}
