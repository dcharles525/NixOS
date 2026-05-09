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
      openssl_1_1       # libcrypto.so.1.1, libssl.so.1.1 — rs2client links against OpenSSL 1.1
      zlib
      vulkan-loader     # Vulkan ICD loader — needed when rs2client uses MESA_LOADER_DRIVER_OVERRIDE=zink
      stdenv.cc.cc.lib  # libstdc++.so.6
    ];
  };

  powerManagement.enable = true;

  # Enable wakeup for USB HID devices (keyboard/mouse) so they can resume from S3 suspend.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usbhid", ATTR{power/wakeup}="enabled"
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
  hardware.logitech.wireless.enableGraphical = true;

  #
  # Bootloader
  #

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "systemd.unified_cgroup_hierarchy=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia_drm.modeset=1"
  ];

  # User Setup

  users.users.d = {
    isNormalUser = true;
    description = "David Johnson";
    extraGroups = [ "networkmanager" "wheel" "docker" "adbusers" ];
  };
  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; host="desktop";};
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
  };

  programs.waybar = {
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    });
  };

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
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
    ]))
    iotop
    sysstat
    claude-code

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
    dunst
    libnotify
    swww
    rofi
    nautilus
    iwd
    slack
    brightnessctl
    pulseaudio
    iw
    lemonbar

    # Misc Apps
    gparted
    rpi-imager
    partclone
    yaak
    qimgv
    libreoffice
    chromium
    gotop
    bambu-studio
    discord
  ];

  services.flatpak = {
    enable = true;
    remotes = [{
      name = "flathub";
      location = "https://flathub.org/repo/flathub.flatpakrepo";
    }];
    packages = [
      "com.adamcake.Bolt"
      "org.freedesktop.Platform.GL.nvidia-595-71-05"
      "org.freedesktop.Platform.GL32.nvidia-595-71-05"
    ];
    overrides = {
      "com.adamcake.Bolt" = {
        Context.devices = "all";
        # RS3 renders via Zink (Mesa OpenGL-over-Vulkan) to avoid NVIDIA's broken
        # EGL+Wayland path. VK_DRIVER_FILES is the critical var — it points Vulkan
        # to the correct NVIDIA ICD so Zink uses the GPU rather than llvmpipe.
        # The GL extension version (nvidia-595-71-05) must exactly match the running
        # driver or Vulkan gets VK_ERROR_DEVICE_LOST. rs_launch_command in
        # ~/.config/bolt-launcher/launcher.json sets the Zink env vars.
        Environment.variables = "__EGL_VENDOR_LIBRARY_DIRS=/usr/lib/x86_64-linux-gnu/GL/glvnd/egl_vendor.d;LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/GL/nvidia-595-71-05/lib;VK_DRIVER_FILES=/usr/lib/x86_64-linux-gnu/GL/vulkan/icd.d/nvidia_icd.json";
      };
    };
  };
  services.tailscale.enable = true;
  programs.vim.enable = true;
  programs.firefox.enable = true;
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
