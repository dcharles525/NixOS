# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./app-configs/vim.nix
    inputs.home-manager.nixosModules.default
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  security.pam.services.hyprlock = {};
  services.displayManager.ly.enable = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Pantheon Desktop Environment.
  # services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.desktopManager.pantheon.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.d = {
    isNormalUser = true;
    description = "David Johnson";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users = {
      "d" = import ./home.nix;
    };
  };

  environment.variables = { 
    EDITOR = "vim"; 
    PATH="$HOME/go/bin:$PATH";
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  programs.vim.defaultEditor = true;
  environment.systemPackages = with pkgs; [
    vim_configurable
    git
    tmux
    k9s
    go
    #unstable.ghostty
    nodejs
    nextcloud-client
    circumflex
    tailscale
    waybar
    dunst
    libnotify
    swww
    rofi-wayland
    yazi
  ];

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

  services.tailscale.enable = true;

  programs.vim.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # programs.hyprlock.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    });
  };

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  /*home-manager.useUserPackages = true;
  home-manager.users.d = {
    home.file."config/hypr/hyperland.conf".text = ''
      monitor = eDP-1, 1920x1080@144, 0x0, 1
      
      $terminal = ghostty
      $fileManager = dolphin
      $menu = wofi --show drun
      
      env = XCURSOR_SIZE,24
      env = HYPRCURSOR_SIZE,24
      general {
        gaps_in = 5
        gaps_out = 20

        border_size = 2

        col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
        col.inactive_border = rgba(595959aa)

        resize_on_border = false
        allow_tearing = false
        layout = dwindle
      }
      
      decoration {
        rounding = 10

        active_opacity = 1.0
        inactive_opacity = 1.0

        shadow {
          enabled = true
          range = 4
          render_power = 3
          color = rgba(1a1a1aee)
        }

        blur {
          enabled = true
          size = 3
          passes = 1

          vibrancy = 0.1696
        }
      }

      animations {
        enabled = yes, please :)

        bezier = easeOutQuint,0.23,1,0.32,1
        bezier = easeInOutCubic,0.65,0.05,0.36,1
        bezier = linear,0,0,1,1
        bezier = almostLinear,0.5,0.5,0.75,1.0
        bezier = quick,0.15,0,0.1,1

        animation = global, 1, 10, default
        animation = border, 1, 5.39, easeOutQuint
        animation = windows, 1, 4.79, easeOutQuint
        animation = windowsIn, 1, 4.1, easeOutQuint, popin 87%
        animation = windowsOut, 1, 1.49, linear, popin 87%
        animation = fadeIn, 1, 1.73, almostLinear
        animation = fadeOut, 1, 1.46, almostLinear
        animation = fade, 1, 3.03, quick
        animation = layers, 1, 3.81, easeOutQuint
        animation = layersIn, 1, 4, easeOutQuint, fade
        animation = layersOut, 1, 1.5, linear, fade
        animation = fadeLayersIn, 1, 1.79, almostLinear
        animation = fadeLayersOut, 1, 1.39, almostLinear
        animation = workspaces, 1, 1.94, almostLinear, fade
        animation = workspacesIn, 1, 1.21, almostLinear, fade
        animation = workspacesOut, 1, 1.94, almostLinear, fade
      }
      
      dwindle {
        pseudotile = true 
        preserve_split = true
      }

      master {
        new_status = master
      }

      misc {
        force_default_wallpaper = -1 
        disable_hyprland_logo = true
      }

      input {
        kb_layout = us
        kb_variant =
        kb_model =
        kb_options =
        kb_rules =

        follow_mouse = 1

        sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

        touchpad {
          natural_scroll = true
        }
      }

      gestures {
        workspace_swipe = false
      }

      device {
        name = epic-mouse-v1
        sensitivity = -0.5
      }

      $mainMod = SUPER # Sets "Windows" key as main modifier

      bind = $mainMod, Q, exec, $terminal
      bind = $mainMod, C, killactive,
      bind = $mainMod, M, exit,
      bind = $mainMod, E, exec, $fileManager
      bind = $mainMod, V, togglefloating,
      bind = $mainMod, R, exec, $menu
      bind = $mainMod, P, pseudo, # dwindle
      bind = $mainMod, J, togglesplit, # dwindle

      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d

      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10

      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10

      bind = $mainMod SHIFT, L, moveactive, 30 0
      bind = $mainMod SHIFT, H, moveactive, -30 0
      bind = $mainMod SHIFT, K, moveactive, 0 -30
      bind = $mainMod SHIFT, J, moveactive, 0 30 

      bind = $mainMod, S, togglespecialworkspace, magic
      bind = $mainMod SHIFT, S, movetoworkspace, special:magic

      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1

      bind = $mainMod, S, exec, rofi -show drun -show-icons

      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow

      bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindel = ,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindel = ,XF86MonBrightnessUp, exec, brightnessctl s 10%+
      bindel = ,XF86MonBrightnessDown, exec, brightnessctl s 10%-

      bindl = , XF86AudioNext, exec, playerctl next
      bindl = , XF86AudioPause, exec, playerctl play-pause
      bindl = , XF86AudioPlay, exec, playerctl play-pause
      bindl = , XF86AudioPrev, exec, playerctl previous

      windowrulev2 = suppressevent maximize, class:.*

      windowrulev2 = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0
    '';
  };*/
  # Allow unfree packages

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
}
