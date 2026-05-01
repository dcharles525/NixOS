{ ... }:
{
  services.hypridle.enable = true;
  services.hypridle.settings = {
    general = {
      lock_cmd = "pidof hyprlock || hyprlock";
      before_sleep_cmd = "pidof hyprlock || hyprlock";
      after_sleep_cmd = "sleep 2; hyprctl dispatch dpms on";
    };
    listener = [
      {
        timeout = 600;
        on-timeout = "brightnessctl -s set 50";
        on-resume = "brightnessctl -r";
      }
      {
        timeout = 600;
        on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
        on-resume = "brightnessctl -rd rgb:kbd_backlight";
      }
      {
        timeout = 900;
        on-timeout = "loginctl lock-session";
      }
      {
        timeout = 1800;
        on-timeout = "hyprctl dispatch dpms off";
        on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
      }
      {
        timeout = 2700;
        on-timeout = "systemctl suspend";
      }
    ];
  };
}
