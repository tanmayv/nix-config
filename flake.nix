{
  description = "My NixOS system configuration (flake-based)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    niri.url = "github:sodiboo/niri-flake";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apollo-flake.url = "github:nil-andreas/apollo-flake";
    apollo-flake.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, sops-nix, niri, hyprland, apollo-flake, ... }@inputs:
  let
    overlays = [
      (final: prev: {
        librepods = prev.callPackage ./pkgs/librepods {};
      })
    ];
    mkHost = name: let
      host =  import ./hosts/${name}/host.nix;
      helper =  import ./modules/core/lib/helper/default.nix { lib = nixpkgs.lib; };
    in 
    nixpkgs.lib.nixosSystem {
      system = host.system;
      specialArgs = { inherit host; inherit helper; inherit hyprland; inherit apollo-flake; inherit nixpkgs; }; # Make host 
      modules = [
          { nixpkgs.overlays = overlays; }
          (inputs.apollo-flake.nixosModules.${host.system}.default)
          ({pkgs, ...}: {
            services.apollo.package = apollo-flake.packages.${pkgs.system}.default;
          })
          sops-nix.nixosModules.sops
          inputs.stylix.nixosModules.stylix
          niri.nixosModules.niri
          ./modules/core
          ./hosts/${name}/hardware-configuration.nix
          ./hosts/${name}/configuration.nix
      ];
    };
  in {
    nixosConfigurations = {
      dragonfly = mkHost "dragonfly";
      zephyrus = mkHost "zephyrus";
      dawnstar = mkHost "dawnstar";
    };
  };
}
