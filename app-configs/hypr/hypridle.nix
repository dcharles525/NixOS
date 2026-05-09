{ specialArgs, ... }:
{
  services.hypridle.enable = true;
  services.hypridle.settings = {
    general = {
      lock_cmd = "pidof hyprlock || hyprlock";
      # Desktop: monitors are permanently connected — just lock, no topology changes needed.
      # ktop: disable externals before suspend so topology changes happen outside the resume
      # path — Hyprland 0.54.3 aborts when outputs disappear mid-resume (see memory/nixos-ktop.md).
      before_sleep_cmd =
        if specialArgs.host == "desktop"
        then "pidof hyprlock || hyprlock"
        else "hyprctl keyword monitor 'HDMI-A-1, disable'; hyprctl keyword monitor 'DP-1, disable'; pidof hyprlock || hyprlock";
      # Desktop: monitors were never disabled, just restore DPMS with extra time for NVIDIA.
      # ktop: reload config to re-enable monitors that were disabled before sleep.
      after_sleep_cmd =
        if specialArgs.host == "desktop"
        then "sleep 3; hyprctl dispatch dpms on"
        else "sleep 2; hyprctl reload; hyprctl dispatch dpms on";
    };
    listener = [
      {
        timeout = 600;
        on-timeout = "brightnessctl -s set 50";
        on-resume = "brightnessctl -r";
      }
    ] ++ (if specialArgs.host != "desktop" then [
      {
        timeout = 600;
        on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
        on-resume = "brightnessctl -rd rgb:kbd_backlight";
      }
    ] else []) ++ [
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
