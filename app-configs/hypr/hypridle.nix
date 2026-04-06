{ ... }:
{
  services.hypridle.enable = true;
  services.hypridle.settings = {
    general = {
      lock_cmd = "hyprlock";
      before_sleep_cmd = "hyprlock";
      after_sleep_cmd = "sleep 1 && hyprctl dispatch dpms on";
    };
    listener = [
      {
        timeout = 300;
        on-timeout = "brightnessctl -s set 50";
        on-resume = "brightnessctl -r";
      }
      {
        timeout = 300;
        on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
        on-resume = "brightnessctl -rd rgb:kbd_backlight";
      }
      {
        timeout = 900;
        on-timeout = "loginctl lock-session";
      }
      {
        timeout = 900;
        on-timeout = "hyprctl dispatch dpms off";
        on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
      }
      {
        timeout = 1800;
        on-timeout = "systemctl suspend";
      }
    ];
  };
}
