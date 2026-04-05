{ config, pkgs, ... }:
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        browser = "${config.programs.firefox.package}/bin/firefox -new-tab";
        dmenu = "${pkgs.rofi}/bin/rofi -dmenu";
        follow = "mouse";
        font = "JetBrains Mono 10";
        format = "<b>%s</b>\\n%b";
        frame_width = 1;
        width = 300;
        origin = "top-right";
        offset = "10x0";
        horizontal_padding = 12;
        icon_position = "off";
        line_height = 0;
        markup = "full";
        padding = 12;
        separator_color = "frame";
        separator_height = 1;
        transparency = 0;
        word_wrap = true;
        corner_radius = 15;
      };

      urgency_low = {
        background = "#000000a6";
        foreground = "#4da1af";
        frame_color = "#4da1af40";
        timeout = 10;
      };

      urgency_normal = {
        background = "#000000a6";
        foreground = "#70a040";
        frame_color = "#70a04040";
        timeout = 15;
      };

      urgency_critical = {
        background = "#00000090";
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
