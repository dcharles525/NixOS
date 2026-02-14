{ ... }:
{
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
}
