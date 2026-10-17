{ config, pkgs, ... }:

let
  # MGX palette, generated from llm-skills/design/tokens.css.
  mgx = (import ./app-configs/mgx.nix).dark;
in
{
  imports = [
    ./app-configs/hypr/hyprland.nix
    ./app-configs/hypr/hypridle.nix
    ./app-configs/hypr/hyprpaper.nix
    ./app-configs/hypr/hyprlock.nix
    ./app-configs/waybar.nix
    ./app-configs/ghostty.nix
    ./app-configs/swaync.nix
    ./app-configs/ags.nix
    ./app-configs/claude.nix
    ./app-configs/bash.nix
  ];

  #
  # Base Home Manager Configuration
  #

  programs.home-manager.enable = true;
  home.username = "d";
  home.homeDirectory = "/home/d";
  home.sessionVariables = {
    EDITOR = "vim";
    ELECTRON_OZONE_PLATFORM_HINT = "x11";
  };
  home.stateVersion = "24.11";
  home.sessionPath = [
    "$HOME/.npm-packages/bin"
    "$HOME/.local/bin"
  ];

  # xdg-desktop-portal scans only the FIRST portals dir in XDG_DATA_DIRS, and
  # home-manager-path (which ships hyprland.portal) wins. Without gtk.portal
  # in the same profile there is no FileChooser portal, so native file
  # dialogs silently fail. Keep this alongside xdg.portal.extraPortals.
  home.packages = [ pkgs.xdg-desktop-portal-gtk ];

  home.file.".config/rofi/config.rasi".text = ''
    * {
      highlight: bold italic;
      scrollbar: false;

      background:                  #${mgx.bg}e6;
      background-color:            transparent;
      foreground:                  #${mgx.ink};
      border-color:                #${mgx.ink};
      separatorcolor:              #${mgx.line};

      normal-background:           transparent;
      normal-foreground:           @foreground;
      alternate-normal-background: transparent;
      alternate-normal-foreground: @foreground;
      selected-normal-background:  #${mgx.ink};
      selected-normal-foreground:  #${mgx.bg};

      active-background:           transparent;
      active-foreground:           #${mgx.cat2};
      alternate-active-background: @active-background;
      alternate-active-foreground: @active-foreground;
      selected-active-background:  #${mgx.ink};
      selected-active-foreground:  #${mgx.bg};

      urgent-background:           transparent;
      urgent-foreground:           #${mgx.alert};
      alternate-urgent-background: @urgent-background;
      alternate-urgent-foreground: @urgent-foreground;
      selected-urgent-background:  #${mgx.alert};
      selected-urgent-foreground:  #${mgx.bg};
    }

    window {
      background-color: @background;
      border:           1px;
      border-color:     @border-color;
      border-radius:    0;
      padding:          10px;
      width:            500px;
    }

    mainbox {
      border:  0;
      padding: 0;
    }

    message {
      border:       1px 0 0;
      border-color: @separatorcolor;
      padding:      4px;
    }

    textbox {
      highlight:  @highlight;
      text-color: @foreground;
    }

    listview {
      border:       1px solid 0 0;
      padding:      8px 0 0;
      border-color: @separatorcolor;
      spacing:      4px;
      scrollbar:    @scrollbar;
      lines:        10;
    }

    element {
      border:        0;
      padding:       6px 8px;
      border-radius: 0;
    }

    element.normal.normal {
      background-color: @normal-background;
      text-color:       @normal-foreground;
    }

    element.normal.urgent {
      background-color: @urgent-background;
      text-color:       @urgent-foreground;
    }

    element.normal.active {
      background-color: @active-background;
      text-color:       @active-foreground;
    }

    element.selected.normal {
      background-color: @selected-normal-background;
      text-color:       @selected-normal-foreground;
    }

    element.selected.urgent {
      background-color: @selected-urgent-background;
      text-color:       @selected-urgent-foreground;
    }

    element.selected.active {
      background-color: @selected-active-background;
      text-color:       @selected-active-foreground;
    }

    element.alternate.normal {
      background-color: @alternate-normal-background;
      text-color:       @alternate-normal-foreground;
    }

    element.alternate.urgent {
      background-color: @alternate-urgent-background;
      text-color:       @alternate-urgent-foreground;
    }

    element.alternate.active {
      background-color: @alternate-active-background;
      text-color:       @alternate-active-foreground;
    }

    scrollbar {
      width:        4px;
      border:       0;
      handle-color: #${mgx.lineStrong};
      handle-width: 8px;
      padding:      0;
    }

    inputbar {
      spacing:          0;
      text-color:       @normal-foreground;
      padding:          8px;
      background-color: transparent;
      border:           0 0 1px;
      border-color:     #${mgx.inkDim};
      border-radius:    0;
      children:         [ prompt, textbox-prompt-sep, entry, case-indicator ];
    }

    case-indicator,
    entry,
    prompt,
    button {
      spacing:          0;
      text-color:       @normal-foreground;
      background-color: transparent;
    }

    button.selected {
      background-color: @selected-normal-background;
      text-color:       @selected-normal-foreground;
    }

    textbox-prompt-sep {
      expand:           false;
      str:              ":";
      text-color:       @normal-foreground;
      margin:           0 0.3em 0 0;
      background-color: transparent;
    }

    element-text, element-icon {
      background-color: inherit;
      text-color:       inherit;
    }
  '';

  xdg.desktopEntries.slack = {
    name = "Slack";
    comment = "Slack Desktop";
    genericName = "Slack Client for Linux";
    exec = "slack --ozone-platform=x11 -s %U";
    icon = "slack";
    type = "Application";
    startupNotify = true;
    categories = [ "GNOME" "GTK" "Network" "InstantMessaging" ];
    mimeType = [ "x-scheme-handler/slack" ];
    settings.StartupWMClass = "Slack";
  };

  xdg.desktopEntries."com.raspberrypi.rpi-imager" = {
    name = "Raspberry Pi Imager";
    comment = "Tool for writing images to SD cards for Raspberry Pi";
    icon = "rpi-imager";
    exec = "rpi-imager %u";
    categories = [ "Utility" ];
    mimeType = [ "x-scheme-handler/rpi-imager" "application/vnd.raspberrypi.imager-manifest+json" ];
    settings.StartupNotify = "false";
  };

  # Mind: the llm-skills card stack in a Chromium --app window.
  xdg.desktopEntries.mind = {
    name = "Mind";
    comment = "Card stack, open items and repo map";
    exec = "/home/d/Documents/Project/LLM/llm-skills/tools/mind app";
    icon = "${./assets/mind.png}";
    terminal = false;
    categories = [ "Utility" ];
    settings.StartupWMClass = "mind";
  };

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
    gtk4.theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    cursorTheme = {
      package = pkgs.catppuccin-cursors.mochaDark;
      name = "catppuccin-mocha-dark-cursors";
    };
    # Libadwaita apps (overskride, iwgtk, pwvucontrol, etc.) ignore
    # gtk4.theme and use their own stylesheet. Override the named accent
    # tokens so they match the MGX one-ink look of rofi and waybar.
    gtk4.extraCss = ''
      @define-color accent_color #${mgx.ink};
      @define-color accent_bg_color #${mgx.ink};
      @define-color accent_fg_color #${mgx.bg};

      @define-color destructive_color #${mgx.alert};
      @define-color destructive_bg_color #${mgx.alert};
      @define-color destructive_fg_color #${mgx.bg};

      @define-color success_color #${mgx.ok};
      @define-color warning_color #${mgx.warn};
      @define-color error_color   #${mgx.alert};
    '';
  };

  xdg.configFile."opencode/config.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    permission = {
      "webfetch" = "allow";
      "bash" = "allow";
      "read" = "allow";
      "edit" = "allow";
      "skill" = "allow";
    };
    model = "ollama/llama3.1-16k:latest";
    provider = {
      ollama = {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama (local)";
        options = {
          baseURL = "http://localhost:11434/v1/";
        };
        models = {
          "qwen2.5-coder:1.5b" = { 
            name = "Qwen 2.5 Coder 1.5B"; 
            "reasoning" = true;
            "tool_call" = true;
            "limit" = {
              "context" = 131072;
              "output" = 65536;
            };
          };
          "qwen2.5-coder-32k:latest" = { name = "Qwen 2.5 Coder 7B (32k ctx)"; "tool_call" = true; };
          "llama3.1:latest" = { name = "Llama 3.1 8B"; "tool_call" = true; };
          "llama3.1-16k:latest" = { name = "Llama 3.1 8B (16k ctx)"; "tool_call" = true; };
          "qwen3:8b" = { name = "Qwen 8B"; };
          "gemma4:e4b" = { name = "Gemma 4 E4B (4.5B)"; "tool_call" = true; };
          "gemma4:e4b-32k" = { name = "Gemma 4 E4B (4.5B) 32k"; "tool_call" = true; };
          "qwen3-coder-128k:latest" = {
            name = "Qwen3 Coder 30B-A3B (128k ctx)";
            "tool_call" = true;
            "limit" = {
              "context" = 131072;
              "output" = 32768;
            };
          };
          "gemma4-128k:latest" = {
            name = "Gemma 4 E4B (4.5B) 128k";
            "reasoning" = true;
            "tool_call" = true;
            "limit" = {
              "context" = 131072;
              "output" = 32768;
            };
          };
          "deepseek-r1-llama-128k:latest" = {
            name = "DeepSeek R1 Distill Llama 8B (128k ctx)";
            "reasoning" = true;
            "tool_call" = true;
            "limit" = {
              "context" = 131072;
              "output" = 32768;
            };
          };
        };
      };
    };
    mcp = {
      excalidraw = {
        type = "local";
        enabled = true;
        command = [
          "docker" "run" "-i" "--rm"
          "-e" "EXPRESS_SERVER_URL=http://beelink:5001"
          "-e" "ENABLE_CANVAS_SYNC=true"
          "ghcr.io/yctimlin/mcp_excalidraw:latest"
        ];
      };
    };
  };
}
