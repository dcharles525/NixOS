{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Newer unstable used only for selected packages (tailscale, claude-code)
    nixpkgs-latest.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    iwmenu.url = "github:e-tho/iwmenu";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    latestPackagesOverlay = { pkgs, ... }: {
      nixpkgs.overlays = [
        (final: prev:
          let
            # legacyPackages ignores this host's nixpkgs.config, so unfree
            # packages (claude-code) need nixpkgs-latest imported with it.
            latest = import inputs.nixpkgs-latest {
              inherit (prev.stdenv.hostPlatform) system;
              inherit (prev) config;
            };
          in {
            inherit (latest) tailscale claude-code;
          })
      ];
    };
  in {
    # use "nixos", or your hostname as the name of the configuration
    # it's a better practice than "default" shown in the video
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/desktop/configuration.nix
          inputs.home-manager.nixosModules.default
          inputs.nix-flatpak.nixosModules.nix-flatpak
          latestPackagesOverlay
        ];
      };
      laptop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/laptop/configuration.nix
          inputs.home-manager.nixosModules.default
          latestPackagesOverlay
        ];
      };
      ktop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/ktop/configuration.nix
          inputs.home-manager.nixosModules.default
          latestPackagesOverlay
        ];
      };
    };
  };
}
