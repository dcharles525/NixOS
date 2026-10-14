# SDDM with a greeter theme that mirrors hyprlock (hypr/hyprlock.nix).
# Curried so each host picks its sleep action, same split as hyprlock:
#   (import ./../../app-configs/sddm { sleep = "hibernate"; })
{ sleep, user ? "d" }:
{ config, pkgs, ... }:
let
  # MGX palette, generated from llm-skills/design/tokens.css.
  mgx = (import ../mgx.nix).dark;
  themeConf = pkgs.writeText "theme.conf" ''
    [General]
    bg=#${mgx.bg}
    ink=#${mgx.ink}
    inkDim=#${mgx.inkDim}
    warn=#${mgx.warn}
    alert=#${mgx.alert}
    user=${user}
    sleep=${sleep}
  '';
  # The background is blurred here rather than in QML so the greeter needs
  # no shader effects (one less thing to go wrong before login on NVIDIA).
  theme = pkgs.runCommand "sddm-theme-mgx" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    dir=$out/share/sddm/themes/mgx
    mkdir -p $dir
    cp ${./theme/Main.qml} $dir/Main.qml
    cp ${./theme/metadata.desktop} $dir/metadata.desktop
    cp ${themeConf} $dir/theme.conf
    magick ${../../assets/background.jpg} \
      -resize 3840x -blur 0x12 -quality 90 $dir/background.jpg
  '';
in
{
  services.displayManager.sddm = {
    enable = true;
    theme = "mgx";
    # X11 greeter where X is already enabled (desktop, NVIDIA); otherwise
    # the Wayland greeter under weston (ktop).
    wayland.enable = !config.services.xserver.enable;
  };
  # The theme has no session picker, so pin what a first login starts.
  services.displayManager.defaultSession = "hyprland";
  environment.systemPackages = [ theme ];
}
