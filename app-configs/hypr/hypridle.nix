{ specialArgs, ... }:
{
  services.hypridle.enable = true;
  services.hypridle.settings = {
    general = {
      lock_cmd = "systemctl --user start hyprlock";
      # s2idle freezes processes in place so hyprlock survives sleep fine.
      # Keeping it alive means dpms-on on wake only resizes surfaces (safe) rather than
      # triggering a full output disconnect/reconnect that crashes a freshly-started hyprlock.
      # systemctl start is idempotent; Restart=on-failure in the hyprlock service handles respawn.
      before_sleep_cmd = "systemctl --user start hyprlock";
      after_sleep_cmd = "sleep 2; hyprctl dispatch dpms on";
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
        # Skip dpms off if hyprlock is already running — dpms off while locked causes
        # topology changes that crash the locker or leave displays unrecoverable on NVIDIA.
        # (see: hyprwm/hyprlock#953 comment by @eliasnema)
        on-timeout = "pgrep -x hyprlock || hyprctl dispatch dpms off";
        on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
      }
      {
        timeout = 2700;
        on-timeout = "systemctl suspend";
      }
    ];
  };
}
