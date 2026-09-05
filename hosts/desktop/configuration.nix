{ config, pkgs, lib, inputs, ... }:
{
  #
  # Config Setup
  #

  imports = [
    ./hardware-configuration.nix
    ./../../app-configs/vim.nix
    ./../../app-configs/tmux.nix
    inputs.home-manager.nixosModules.default
  ];
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  environment.variables = {
    EDITOR = "vim";
    PATH="$HOME/go/bin:$PATH";
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ADW_DISABLE_PORTAL = "1";
  };
  services.udisks2.enable = true;
  programs.vim.defaultEditor = true;
  system.stateVersion = "24.11";
  services.power-profiles-daemon.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Enable nix-ld so unpatched binaries (e.g. rs2client from Bolt) can resolve
  # shared libraries via NIX_LD_LIBRARY_PATH at runtime.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      SDL2
      libglvnd          # libEGL.so.1, libOpenGL.so.0, libGL.so.1 — dispatch layer
      mesa              # libEGL_mesa.so.0, libGLX_mesa.so.0 — Mesa implementation for Zink
      zlib
      vulkan-loader     # Vulkan ICD loader — needed when rs2client uses MESA_LOADER_DRIVER_OVERRIDE=zink
      stdenv.cc.cc.lib  # libstdc++.so.6
    ];
  };

  powerManagement.enable = true;

  # Enable wakeup for USB HID devices (keyboard/mouse) so they can resume from s2idle.
  # Logitech Bolt receiver (046d:c548) excluded — it polls continuously and wakes s2idle instantly.
  # Realtek RTL8821CE Bluetooth radio (13d3:3533) — disable USB autosuspend. Default 2s
  # timeout suspends the chip within seconds of BT going idle, and wakeup is off, so
  # trusted headphones can't page the host to reconnect after they've been powered off.
  # ENV{DEVTYPE}=="usb_device" targets the parent USB device node (which owns
  # power/wakeup) instead of its interfaces (which don't and silently no-op).
  #
  # PCI-level wakeup disabled for RTL8168 Ethernet (04:00.0) and RTL8821CE
  # Wi-Fi (03:00.0) and their PCIe root ports (00:1c.2, 00:1c.0). Realtek NICs
  # default to WOL/WoWLAN enabled by firmware; the constant broadcast/mDNS
  # traffic in any real network wakes s2idle within ~3 seconds. Disabling PCI
  # wakeup on both the device and its root port ensures a PME cannot propagate.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", DRIVERS=="usbhid", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c548", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="13d3", ATTRS{idProduct}=="3533", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:04:00.0", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:03:00.0", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:00:1c.2", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:00:1c.0", ATTR{power/wakeup}="disabled"
  '';


  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings = {
      dns = [ "1.1.1.1" ];
  };

  services.fprintd = {
    enable = true;
    package = pkgs.fprintd-tod;  # If you're using the "tod" variant
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-goodix;
    };
  };

  hardware.logitech.wireless.enable = true;
  programs.solaar.enable = true;

  #
  # Bootloader
  #

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Default entry auto-selects with no delay — critical for hibernate wake
  # UX (otherwise the systemd-boot menu appears every resume). Hold SPACE
  # during POST to interrupt if you need to pick an older generation.
  boot.loader.timeout = 0;
  boot.kernelParams = [
    "systemd.unified_cgroup_hierarchy=1"
    # NVIDIA VRAM save/restore across S4 (hibernate). Still required even
    # though we no longer use suspend — hibernate writes the RAM image to
    # swap and needs VRAM contents preserved into system RAM first.
    #   - PreserveVideoMemoryAllocations=1: nvidia-suspend.service saves VRAM
    #     to system RAM (via /var/tmp) so it ends up in the hibernation image.
    #   - nvidia_drm.fbdev=1: nvidia owns fb0 directly, so DRM re-init on
    #     resume doesn't race with fbcon takeover; avoids the sync FD
    #     semaphore surface error family (__nv_drm_semsurf_wait_fence_work_cb).
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia_drm.modeset=1"
    "nvidia_drm.fbdev=1"
    # Desktop is hibernate-only. S3 hard-freezes at ENTRY on NVIDIA (3x
    # confirmed with 595.99.02). s2idle held after Bolt/WOL wake fixes but
    # kept fans/RGB lit — not what we want, so all suspend paths route to
    # hibernate now (waybar button, hyprlock icon, hypridle timeout).
    # Long s2idle (>several hours) loses VRAM self-refresh on NVIDIA → modeset
    # can't recover → black displays on wake. Route the kernel at swap so
    # suspend-then-hibernate can promote to S4 after HibernateDelaySec.
    "resume=UUID=2271fa51-737a-4ac4-b435-3c6aace266a0"
  ];

  # Auto-promote s2idle → hibernate after 1h idle in suspend.
  # Short sleeps stay fast (s2idle), overnight gets a clean GPU cold-start via S4.
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "1h";
  };

  # User Setup

  users.users.d = {
    isNormalUser = true;
    description = "David Johnson";
    extraGroups = [ "networkmanager" "wheel" "docker" "adbusers" ];
  };
  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; host="desktop"; };
    users = {
      "d" = import ./../../home.nix;
    };
  };

  #
  # Networking
  #
  
  networking.hostName = "d";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable and configure bluetooth
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Name = "DTop";
        ControllerMode = "dual";
        FastConnectable = "true";
        Experimental = "true";
      };
      Policy = {
        AutoEnable = "true";
        # Actively reconnect trusted devices advertising these profiles when the
        # radio sees them. A2DP sink + AVRCP + HFP handset cover audio headphones.
        ReconnectUUIDs = "0000110b-0000-1000-8000-00805f9b34fb,0000110e-0000-1000-8000-00805f9b34fb,0000111e-0000-1000-8000-00805f9b34fb";
        ReconnectAttempts = "7";
        ReconnectIntervals = "1,2,4,8,16,32,64";
      };
    };
  };

  networking.firewall.enable = true;

  #
  # Time and Internationalisation
  #

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  #
  # Display and DE Enablement
  #

  services.displayManager.ly.enable = true;
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  hardware.nvidia-container-toolkit.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # systemd 256+ has a known race freezing user.slice on proprietary NVIDIA
  # drivers (nixpkgs#371058). Applied only to systemd-hibernate since desktop
  # never uses the plain suspend paths (hibernate-only).
  systemd.services = {
    systemd-hibernate.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
    disable-wol-enp4s0 = {
      description = "Disable Wake-on-LAN on enp4s0";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-pre.target" ];
      bindsTo = [ "sys-subsystem-net-devices-enp4s0.device" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp4s0 wol d";
        RemainAfterExit = true;
      };
    };

    # /proc/acpi/wakeup is toggle-based: writing the device name flips its
    # state. AWAC (RTC alarm) and XHCI (USB controller) are BIOS-armed to
    # wake from S4 and cause hibernate to auto-resume on this box.
    disable-acpi-wake-sources = {
      description = "Disable AWAC (RTC) and XHCI (USB) ACPI S4 wake sources";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "disable-acpi-wake" ''
          set -eu
          for dev in AWAC XHCI; do
            if grep -qE "^$dev[[:space:]].*enabled" /proc/acpi/wakeup; then
              echo "$dev" > /proc/acpi/wakeup
            fi
          done
        '';
        RemainAfterExit = true;
      };
    };
  };

  security.pam.services.hyprlock = {};
  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    font-awesome
    liberation_ttf
    mplus-outline-fonts.githubRelease
    #nerdfonts
    noto-fonts
    noto-fonts-color-emoji
    proggyfonts
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs.hyprland.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../../app-configs/hypr/hyprland-session-lock-null-guard.patch ];
    });
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  programs.waybar = {
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    });
  };

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.configPackages = [ pkgs.xdg-desktop-portal-hyprland ];

  #
  # Enable sound with pipewire.
  #

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  #
  # App Configuration
  #

  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  environment.systemPackages = with pkgs; [
    # Developer Tools
    android-tools
    vim-full
    go
    zig
    protobuf
    openssl
    git
    nmap
    tmux
    k9s
    yarn
    nodejs
    tailscale
    k3d
    minikube
    gnumake
    kubectl
    socat
    kubernetes-helm
    jq
    yq
    wget
    zip
    unzip
    mariadb
    dbeaver-bin
    docker-buildx
    pinentry-curses 
    (python313.withPackages (ps: with ps; [
      pip
      requests
      numpy
      flask
      pytest
    ]))
    iotop
    sysstat
    claude-code
    lazygit
    gh

    # Computer Environment
    waybar
    gum
    ghostty
    xhost
    hyprpaper
    hyprshot
    rofi-bluetooth
    catppuccin-cursors.mochaMauve
    inputs.iwmenu.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Media
    circumflex
    swaynotificationcenter
    libnotify
    awww
    rofi
    nautilus
    iwd
    brightnessctl
    pulseaudio
    iw
    lemonbar
    opencode
    playerctl
    overskride
    iwgtk
    pwvucontrol

    # Misc Apps
    partclone
    qimgv
    libreoffice
    chromium
    gotop
  ];

  services.flatpak = {
    enable = true;
    remotes = [{
      name = "flathub";
      location = "https://flathub.org/repo/flathub.flatpakrepo";
    }];
    packages = [
      "com.adamcake.Bolt"
      "org.freedesktop.Platform.GL.nvidia-595-99-02"
      "org.freedesktop.Platform.GL32.nvidia-595-99-02"
    ];
    overrides = {
      "com.adamcake.Bolt" = {
        Context.devices = "all";
        # RS3 renders via Zink (Mesa OpenGL-over-Vulkan) to avoid NVIDIA's broken
        # EGL+Wayland path. VK_DRIVER_FILES is the critical var — it points Vulkan
        # to the correct NVIDIA ICD so Zink uses the GPU rather than llvmpipe.
        # The GL extension version (nvidia-595-99-02) must exactly match the running
        # driver or Vulkan gets VK_ERROR_DEVICE_LOST. rs_launch_command in
        # ~/.config/bolt-launcher/launcher.json sets the Zink env vars.
        Environment.variables = "__EGL_VENDOR_LIBRARY_DIRS=/usr/lib/x86_64-linux-gnu/GL/glvnd/egl_vendor.d;LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/GL/nvidia-595-99-02/lib;VK_DRIVER_FILES=/usr/lib/x86_64-linux-gnu/GL/vulkan/icd.d/nvidia_icd.json";
      };
    };
  };
  services.tailscale.enable = true;
  programs.vim.enable = true;
  programs.firefox.enable = true;
  # programs.opencode.settings = {}; # module not in current nixpkgs-unstable yet; re-enable after nix flake update nixpkgs
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

}
