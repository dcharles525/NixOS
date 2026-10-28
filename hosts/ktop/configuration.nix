{ config, pkgs, lib, inputs, ... }:

let
  hyprland-pkg = (inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland).overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ../../app-configs/hypr/hyprland-tc1.patch ];
  });

  # lazydocker reads the docker context store but ships no ssh:// connection
  # helper, so it tries to speak HTTP at sshd and times out. Forward the remote
  # socket instead and point DOCKER_HOST at the local end.
  # Target host is an ssh alias from ~/.ssh/config (not tracked in this repo).
  lazydocker-remote = pkgs.writeShellScriptBin "lazydocker-remote" ''
    set -euo pipefail

    HOST="''${LAZYDOCKER_REMOTE_HOST:-dockerhost}"
    SOCK="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/docker-$HOST.sock"

    if ! ${pkgs.curl}/bin/curl -s --max-time 5 --unix-socket "$SOCK" \
        http://localhost/_ping >/dev/null 2>&1; then
      rm -f "$SOCK"

      # ControlPath=none: with multiplexing on, the forward is owned by this
      # short-lived client and dies with it.
      ${pkgs.openssh}/bin/ssh -f -N -T \
        -o ControlPath=none \
        -o ExitOnForwardFailure=yes \
        -L "$SOCK:/var/run/docker.sock" "$HOST"
    fi

    DOCKER_HOST="unix://$SOCK" exec ${pkgs.lazydocker}/bin/lazydocker "$@"
  '';

  # One-shot answer to "where did the disk go": the buckets that silently
  # fill this machine (Trash, docker, nix store), then the biggest dirs in
  # $HOME. `diskreport --gui` opens baobab's ring chart to drill in; `gdu ~`
  # is the terminal equivalent. gdu over du: du took >200s on ~/.cache.
  diskreport = pkgs.writeShellScriptBin "diskreport" ''
    set -uo pipefail
    PATH=${lib.makeBinPath (with pkgs; [
      coreutils gdu findutils gawk gnugrep gnused
    ])}:$PATH

    if [ "''${1:-}" = "--gui" ]; then
      exec ${pkgs.baobab}/bin/baobab "''${2:-$HOME}"
    fi

    row() { printf '  %-30s %10s\n' "$1" "$2"; }
    sz() {
      [ -e "$1" ] || { echo "-"; return; }
      gdu -n -s -p "$1" 2>/dev/null | awk '{print $1 $2}'
    }

    echo "Filesystem"
    df -h / | awk 'NR==2 {printf "  %s used of %s, %s free (%s)\n",
      $3, $2, $4, $5}'

    echo; echo "Reclaimable buckets"
    row "Trash" "$(sz "$HOME/.local/share/Trash")"
    row "~/.cache" "$(sz "$HOME/.cache")"
    row "~/.minikube" "$(sz "$HOME/.minikube")"

    if docker info >/dev/null 2>&1; then
      docker system df --format '{{.Type}}\t{{.Reclaimable}}' |
        while IFS=$'\t' read -r t r; do row "docker $t" "$r"; done
    else
      row "docker" "daemon off"
    fi

    dead=$(nix-store --gc --print-dead 2>/dev/null |
      xargs -r du -sch 2>/dev/null | tail -1 | cut -f1)
    row "nix store (dead paths)" "''${dead:-0}"
    gens=$(ls /nix/var/nix/profiles | grep -c '^system-.*-link$')
    row "nix system generations" "$gens"

    echo; echo "Biggest in $HOME"
    gdu -n -p "$HOME" 2>/dev/null | head -12 | sed 's/^/  /'

    echo
    echo "Drill in: diskreport --gui [path]  |  gdu [path]"
  '';
in

{
  #
  # Config Setup
  #

  imports = [
    ./hardware-configuration.nix
    ./../../app-configs/vim.nix
    ./../../app-configs/tmux.nix
    (import ./../../app-configs/sddm { sleep = "suspend"; })
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
  programs.solaar.enable = true;

  #
  # Bootloader
  #

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "systemd.unified_cgroup_hierarchy=1" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Disable PSR and display C-states to reduce TC1 link training flicker
  # on USB-C/Thunderbolt port. TC1 briefly removes wl_output on plug-in
  # which crashes hyprlock — these reduce the retraining trigger frequency.
  boot.extraModprobeConfig = "options i915 enable_psr=0 enable_dc=0 enable_dp_mst=0";

  # User Setup

  users.users.d = {
    isNormalUser = true;
    description = "David Johnson";
    extraGroups = [ "networkmanager" "wheel" "docker" "adbusers" "disk" "kvm" ];
  };
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; host="ktop"; };
    users = {
      "d" = import ./../../home.nix;
    };
  };

  #
  # Networking - ROLLBACK: Keep it simple
  #

  networking.hostName = "d";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;
  networking.hosts."127.0.0.1" = ["localhost" "epinio.127.0.0.1.sslip.io" "auth.127.0.0.1.sslip.io"];
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
  services.fwupd.enable = true;
  # Optimize upower to not slow boot
  services.upower.noPollBatteries = false;

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

  # Retain coredumps so we can backtrace Hyprland/hyprlock/hyprpaper aborts
  # on suspend/resume. Inspect with: coredumpctl info <exe-or-pid>
  systemd.coredump.settings.Coredump = {
    Storage = "external";
    Compress = "yes";
    ProcessSizeMax = "2G";
    MaxUse = "2G";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
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

    wireplumber.extraConfig = {
      "99-audio-rules" = {
        "monitor.alsa.rules" = [
          {
            matches = [ [ { "node.name" = "~alsa_output.*hdmi.*"; } ] ];
            actions = {
              update-props = {
                "priority.session" = 0;
              };
            };
          }
          {
            matches = [ [ { "node.name" = "~alsa_output.*dp.*"; } ] ];
            actions = {
              update-props = {
                "priority.session" = 0;
              };
            };
          }
          {
            matches = [ [ { "device.name" = "alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic"; } ] ];
            actions = {
              update-props = {
                "api.acp.auto-profile" = true;
              };
            };
          }
        ];
      };
    };
  };

  #
  # App Configuration
  #

  programs.nix-ld.enable = true;

  # Rancher Desktop ships only an AppImage on Linux; not in nixpkgs
  # (packaging request NixOS/nixpkgs#196440 was closed as not planned).
  # The default FHS env ships libpng12; Electron needs libpng16.so.16, so
  # Rancher Desktop dies at startup with
  # `libpng16.so.16: cannot open shared object file`. Overriding the package
  # here (rather than adding one to systemPackages) also covers the binfmt path.
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [ pkgs.libpng ];
    };
  };

  # Rancher Desktop runs unprivileged (adminAccess: false), so its port
  # forwarder cannot bind Traefik's 80/443 and Epinio's ingress is unreachable
  # from the host. This is a threshold, not a single port: 80 makes everything
  # from 80 up bindable, 443 included. It must be in place *before* Rancher
  # Desktop starts — the forwarder claims ports once at startup and never
  # retries, so setting it afterwards leaves 80/443 unbound until a restart.
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;
  users.groups.adbusers = {};
  services.udisks2.enable = true;
  # GNOME turns gvfs on for you; Hyprland does not. Without it nautilus has
  # no trash:// backend ("trash locations are not supported"), and `gio`
  # and network mounts are missing too.
  services.gvfs.enable = true;
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0660", GROUP="adbusers"
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0660", GROUP="adbusers"
    SUBSYSTEM=="block", ATTRS{removable}=="1", MODE="0660", GROUP="disk"
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
      # Stock rpi-imager is unusable here for two unrelated reasons:
      #   - it refuses to start writing unless geteuid() == 0, even though `d`
      #     is in group `disk` and removable devices are 0660 root:disk, so the
      #     real I/O succeeds unprivileged. fakeroot satisfies only the check.
      #   - its native (portal) file dialog filters to *.img/zip/gz/xz/zst/wic
      #     and hides *.iso. Only the QML dialog lists iso, and it needs no
      #     portal, so it also survives being run as root.
      # Running under sudo cannot work: root has no session portal, so the
      # native picker comes up empty. This keeps it unprivileged instead.
      rpi-imager =
        let
          # --qml-file-dialogs is a GUI-only option; the --cli parser rejects
          # it outright, so only pass it when not in CLI mode.
          launcher = prev.writeShellScript "rpi-imager-launcher" ''
            imager=${prev.rpi-imager}/bin/rpi-imager
            fakeroot=${prev.fakeroot}/bin/fakeroot

            case " ''$* " in
              *" --cli "*) exec "''$fakeroot" "''$imager" "''$@" ;;
            esac

            exec "''$fakeroot" "''$imager" --qml-file-dialogs "''$@"
          '';
        in
        prev.symlinkJoin {
          name = "rpi-imager-wrapped-${prev.rpi-imager.version}";
          paths = [ prev.rpi-imager ];

          postBuild = ''
            rm "$out/bin/rpi-imager"
            ln -s ${launcher} "$out/bin/rpi-imager"
          '';
        };
    })
  ];

  environment.systemPackages = with pkgs; [
    # Developer Tools
    android-tools
    vim-full
    ripgrep
    go_1_26
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
    ruby
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
    pass # Rancher Desktop stores registry credentials here on Linux
    hugo
    freerdp
    gnome-connections
    pinentry-curses
    iotop
    sysstat
    openfortivpn
    openfortivpn-webview
    (python313.withPackages (ps: with ps; [
      pip
      requests
      numpy
      flask
      flake8
      pyyaml
      alembic
    ]))
    devcontainer
    mermaid-cli
    k6
    openshift
    argocd
    lazydocker
    lazydocker-remote
    diskreport
    gdu
    baobab
    lazygit
    gh
    azure-cli
    terraform

    # Clipboard
    wl-clipboard

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
    brightnessctl
    pulseaudio
    iw
    lemonbar
    go-task

    # Media
    circumflex
    swaynotificationcenter
    libnotify
    awww
    rofi
    nautilus
    iwd
    slack
    playerctl
    overskride
    iwgtk
    pwvucontrol
    # openshot-qt wrapped with the Qt SVG plugin: without it the export
    # dialog's hw-accel icons are null QIcons, which PySide6 treats as falsy,
    # so every export target gets skipped and the dropdowns are empty
    # openshot-qt and qtsvg both come from the pinned nixpkgs-openshot (see
    # flake.nix) so the plugin matches the Qt that openshot was built against.
    (let op = inputs.nixpkgs-openshot.legacyPackages.${pkgs.stdenv.hostPlatform.system}; in
    symlinkJoin {
      name = "openshot-qt-svg-fix";
      paths = [ op.openshot-qt ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/openshot-qt \
          --prefix QT_PLUGIN_PATH : ${op.qt6.qtsvg}/lib/qt-6/plugins
      '';
    })

    # Misc Apps
    asciinema
    chromium
    bc
    gotop
    gparted
    rpi-imager
    partclone
    yaak
    postman
    qimgv
    libreoffice
  ] ++ [
    pkgs.addDriverRunpath
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

  # rpi-imager 2.x hardcodes /usr/bin/pkexec to elevate before writing, and
  # passes --disable-internal-agent so it depends on hyprpolkitagent below.
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/pkexec - - - - /run/wrappers/bin/pkexec"
  ];

  # Hyprland ships no polkit authentication agent, so every auth_admin action
  # (gparted, rpi-imager elevation) failed with no prompt on screen.
  systemd.user.services.hyprpolkitagent = {
    description = "Hyprland polkit authentication agent";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  services.tailscale.enable = true;
  programs.vim.enable = true;
  programs.firefox.enable = true;
}
