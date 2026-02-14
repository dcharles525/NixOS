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

  boot.initrd.luks.devices."luks-bc326299-90c0-4725-a27c-7ff11256edc9".device = "/dev/disk/by-uuid/bc326299-90c0-4725-a27c-7ff11256edc9";

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password-gui"
    "1password"
  ];
  environment.variables = {
    EDITOR = "vim";
    PATH="$HOME/go/bin:$PATH";
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ADW_DISABLE_PORTAL = "1";
  };
  environment.shellAliases = {
    docker = "sudo systemctl start docker 2>/dev/null; command docker";
    docker-compose = "sudo systemctl start docker 2>/dev/null; command docker-compose";
  };
  programs.vim.defaultEditor = true;
  system.stateVersion = "24.11";

  # Boot optimization
  systemd.services.systemd-udev-settle.enable = false;
  services.power-profiles-daemon.enable = true;
  systemd.network.wait-online.enable = false;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Docker optimization - manual start to avoid blocking boot
  # Docker is disabled at boot for fast startup. Start it manually when needed:
  #   sudo systemctl start docker
  #
  # Docker maintenance commands:
  #   Check disk usage:        docker system df
  #   Clean unused data:       docker system prune -a --volumes
  #   Remove all volumes:      docker volume rm $(docker volume ls -q)
  #   Clean build cache:       docker builder prune -a
  virtualisation.docker.enable = true;

  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

  #
  # Bootloader
  #

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "systemd.unified_cgroup_hierarchy=1" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # User Setup

  users.users.d = {
    isNormalUser = true;
    description = "David Johnson";
    extraGroups = [ "networkmanager" "wheel" "docker" "adbusers" ];
  };
  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users = {
      "d" = import ./../../home.nix;
    };
  };

  #
  # Networking - ROLLBACK: Keep it simple
  #

  networking.hostName = "d";
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;

  systemd.services.NetworkManager-wait-online.enable = false;

  services.printing.enable = true;

  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Name = "Hello";
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
  services.upower.enable = true;
  # Optimize upower to not slow boot
  services.upower.noPollBatteries = false;
  services.displayManager.ly.enable = true;

  hardware.graphics = {
    enable = true;
  };
  security.pam.services.hyprlock = {};

  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    font-awesome
    liberation_ttf
    mplus-outline-fonts.githubRelease
    noto-fonts
    noto-fonts-emoji
    proggyfonts
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
      };
      hyprland = {
        default = [ "hyprland" "gtk" ];
      };
    };
  };

  #
  # Enable sound with pipewire - ADDED: Realtime priority fix
  #

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    { domain = "@users"; item = "rtprio"; type = "-"; value = 1; }
  ];
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # Add low-latency settings
    extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 1024;
        default.clock.min-quantum = 512;
        default.clock.max-quantum = 2048;
      };
    };
  };

  #
  # App Configuration
  #

  programs.nix-ld.enable = true;
  programs.adb.enable = true;
  services.udisks2.enable = true;
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0660", GROUP="adbusers"
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0660", GROUP="adbusers"
  '';

  nixpkgs.overlays = [
    (final: prev: {
      postman = prev.postman.overrideAttrs (old: rec {
        version = "20231205182607";
        src = final.fetchurl {
          url = "https://web.archive.org/web/${version}/https://dl.pstmn.io/download/latest/linux_64";
          sha256 = "sha256-PthETmSLehg6eWpdDihH1juwiyZdJvzr+qyG2YYuEZI=";
          name = "${old.pname}-${version}.tar.gz";
        };
      });
    })

    (final: prev: {
      go_1_22 = (import (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.05.tar.gz";
        sha256 = "1lr1h35prqkd1mkmzriwlpvxcb34kmhc9dnr48gkm8hh089hifmx";
      }) {
        inherit (final) config system;
      }).go_1_22;
    })
  ];

  environment.systemPackages = with pkgs; [
    # Developer Tools
    vim_configurable
    go_1_22
    golangci-lint
    protobuf
    openssl
    git
    pack
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
    duf
    zip
    gzip
    pigz
    udev
    e2fsprogs
    partimage
    parted
    gcc
    unzip
    mariadb
    dbeaver-bin
    docker-buildx
    android-studio
    jdk21
    gnupg
    hugo
    tigervnc
    pinentry-curses
    iotop
    sysstat
    openfortivpn
    openfortivpn-webview
    (python311.withPackages (ps: with ps; [
      pip
      requests
      numpy
      flask
      flake8
    ]))

    # Computer Environment
    waybar
    gum
    ghostty
    xorg.xhost
    hyprpaper
    hyprshot
    rofi-bluetooth
    catppuccin-cursors.mochaMauve
    inputs.iwmenu.packages.${pkgs.system}.default
    brightnessctl
    pulseaudio
    iw
    lemonbar

    # Media
    circumflex
    dunst
    libnotify
    swww
    rofi-wayland
    nautilus
    iwd
    slack

    # Misc Apps
    bc
    gotop
    gparted
    rpi-imager
    partclone
    yaak
    postman
    qimgv
    libreoffice
  ];

  nixpkgs.config.android_sdk.accept_license = true;



  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "d" ];
  };

  services.tailscale.enable = true;
  programs.vim.enable = true;
  programs.firefox.enable = true;
}
