{ config, pkgs, ... }:
let
  # MGX palette, generated from llm-skills/design/tokens.css.
  mgx = (import ./mgx.nix).dark;
in
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        browser = "${config.programs.firefox.package}/bin/firefox -new-tab";
        dmenu = "${pkgs.rofi}/bin/rofi -dmenu";
        follow = "mouse";
        font = "Chivo Mono, JetBrainsMono Nerd Font 10";
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
        corner_radius = 0;
      };

      urgency_low = {
        background = "#${mgx.bg}e6";
        foreground = "#${mgx.inkDim}";
        frame_color = "#${mgx.lineStrong}";
        timeout = 10;
      };

      urgency_normal = {
        background = "#${mgx.bg}e6";
        foreground = "#${mgx.ink}";
        frame_color = "#${mgx.ink}";
        timeout = 15;
      };

      urgency_critical = {
        background = "#${mgx.bg}";
        foreground = "#${mgx.alert}";
        frame_color = "#${mgx.alert}";
        timeout = 0;
      };

      shortcuts = {
        context = "mod4+grave";
        close = "mod4+shift+space";
      };
    };
  };
}
