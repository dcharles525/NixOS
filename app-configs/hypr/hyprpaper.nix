{ ... }:
let
  background = builtins.path { path = ../../assets/background.jpg; name = "background.jpg"; };
in
{
  services.hyprpaper.enable = true;
  services.hyprpaper.settings = {
    splash = false;
    splash_offset = 2;

    wallpaper = [
      {
        monitor = "eDP-1";
        path = "${background}";
      }
      {
        monitor = "HDMI-A-1";
        path = "${background}";
      }
      {
        monitor = "DP-1";
        path = "${background}";
      }
    ];
  };
}
