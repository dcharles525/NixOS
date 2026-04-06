{ config, pkgs, ... }:

{
  imports = [
    ./app-configs/hypr/hyprland.nix
    ./app-configs/hypr/hypridle.nix
    ./app-configs/hypr/hyprpaper.nix
    ./app-configs/hypr/hyprlock.nix
    ./app-configs/waybar.nix
    ./app-configs/ghostty.nix
    ./app-configs/dunst.nix
  ];

  #
  # Base Home Manager Configuration
  #

  programs.home-manager.enable = true;
  programs.bash.enable = true;
  home.username = "d";
  home.homeDirectory = "/home/d";
  home.sessionVariables = {
    EDITOR = "vim";
  };
  home.stateVersion = "24.11";
  home.sessionPath = [ "$HOME/.npm-packages/bin" ];

  home.file.".config/rofi/config.rasi".text = ''
    * {
      highlight: bold italic;
      scrollbar: false;

      background:                  #000000a6;
      background-color:            transparent;
      foreground:                  #f2f3f4;
      border-color:                #FFC519;
      separatorcolor:              #ffffff14;

      normal-background:           transparent;
      normal-foreground:           @foreground;
      alternate-normal-background: transparent;
      alternate-normal-foreground: @foreground;
      selected-normal-background:  #ffffff1a;
      selected-normal-foreground:  #FFC519;

      active-background:           #ffffff1a;
      active-foreground:           #FFC519;
      alternate-active-background: @active-background;
      alternate-active-foreground: @active-foreground;
      selected-active-background:  #ffffff26;
      selected-active-foreground:  #FFC519;

      urgent-background:           #dd563340;
      urgent-foreground:           #dd5633;
      alternate-urgent-background: @urgent-background;
      alternate-urgent-foreground: @urgent-foreground;
      selected-urgent-background:  #dd563366;
      selected-urgent-foreground:  #dd5633;
    }

    window {
      background-color: @background;
      border:           1px;
      border-color:     @border-color;
      border-radius:    15px;
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
      border-radius: 10px;
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
      handle-color: #ffffff26;
      handle-width: 8px;
      padding:      0;
    }

    inputbar {
      spacing:          0;
      text-color:       @normal-foreground;
      padding:          8px;
      background-color: #ffffff0d;
      border-radius:    10px;
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

  xdg.desktopEntries."com.raspberrypi.rpi-imager" = {
    name = "Raspberry Pi Imager";
    comment = "Tool for writing images to SD cards for Raspberry Pi";
    icon = "rpi-imager";
    exec = "rpi-imager %u";
    categories = [ "Utility" ];
    mimeType = [ "x-scheme-handler/rpi-imager" "application/vnd.raspberrypi.imager-manifest+json" ];
    settings.StartupNotify = "false";
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
      name = "pkgs.catppuccin-cursors.mochaDark";
    };
  };
}
