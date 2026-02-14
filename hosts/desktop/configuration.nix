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
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
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
  boot.kernelParams = [ "systemd.unified_cgroup_hierarchy=1" ];

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
  # Networking
  #
  
  networking.hostName = "d";
  networking.networkmanager.enable = true;
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
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
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
    noto-fonts-emoji
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
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.configPackages = [ pkgs.xdg-desktop-portal-gtk ];

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

  nixpkgs.config.packageOverrides = pkgs: {
    bolt-launcher = pkgs.bolt-launcher.override {
      enableRS3 = true;
    };
  };

  environment.systemPackages = with pkgs; [
    # Developer Tools
    vim_configurable
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
    (python311.withPackages (ps: with ps; [
      pip
      requests
      numpy
      flask
    ]))
    iotop
    sysstat

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

    # Media
    circumflex
    dunst
    libnotify
    swww
    rofi-wayland
    nautilus
    iwd
    slack
    brightnessctl
    pulseaudio
    iw
    lemonbar

    # Misc Apps
    bolt-launcher
    runescape
    gparted
    rpi-imager
    partclone
    yaak
    qimgv
    libreoffice
    chromium
    gotop
  ];

  services.tailscale.enable = true;
  programs.vim.enable = true;
  programs.firefox.enable = true;

}


