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
  home.username = "d";
  home.homeDirectory = "/home/d";
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
}
