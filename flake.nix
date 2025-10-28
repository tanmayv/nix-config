{
  description = "My NixOS system configuration (flake-based)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };  
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-xr.url = "github:nix-community/nixpkgs-xr";
  };

  outputs = { self, nixpkgs, nixpkgs-xr, sops-nix, home-manager, hyprland, ... }@inputs:
  let 
    mkHost = name: let
      host =  import ./hosts/${name}/host.nix;
      helper =  import ./modules/core/lib/helper/default.nix { lib = nixpkgs.lib; };
    in 
    nixpkgs.lib.nixosSystem {
      system = host.system;
      specialArgs = { inherit host; inherit helper; inherit hyprland; }; # Make host 
      modules = [
          sops-nix.nixosModules.sops
          inputs.stylix.nixosModules.stylix
          nixpkgs-xr.nixosModules.nixpkgs-xr
          ./modules/core
          ./hosts/${name}/hardware-configuration.nix
          ./hosts/${name}/configuration.nix
      ];
    };
  in {
    nixosConfigurations = {
      dragonfly = mkHost "dragonfly";
      zephyrus = mkHost "zephyrus";
    };
  };
}

