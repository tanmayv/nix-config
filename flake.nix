{
  description = "My NixOS system configuration (flake-based)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri.url = "github:sodiboo/niri-flake";
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-core = {
      url = "path:/home/tanmay/projects/nix/home-manager-core";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    extensions = {
      url = "github:tanmayv/home-manager-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nvim-nix.follows = "nvim-nix";
    };
    nvim-nix = {
      url = "path:/home/tanmay/projects/nix/neovim-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apollo-flake.url = "github:nil-andreas/apollo-flake";
    apollo-flake.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    heimdall = {
      url = "path:/home/tanmay/heimdall-agent-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, sops-nix, niri, apollo-flake, home-manager, home-manager-core, extensions, heimdall, ... }@inputs:
  let
    overlays = [
      (final: prev: {
        librepods = prev.callPackage ./pkgs/librepods {};
        openswarm = prev.callPackage ./pkgs/openswarm {};
      })
    ];
    mkHost = name: let
      host =  import ./hosts/${name}/host.nix;
      helper =  import ./modules/core/lib/helper/default.nix { lib = nixpkgs.lib; };
    in 
    nixpkgs.lib.nixosSystem {
      system = host.system;
      specialArgs = { inherit host; inherit helper; inherit apollo-flake; inherit nixpkgs; zen-browser = inputs.zen-browser; }; # Make host 
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
          ./modules/zsh/default.nix
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

    homeConfigurations = builtins.listToAttrs (map (name:
      let
        host = import ./hosts/${name}/host.nix;
        pkgs = import nixpkgs {
          system = host.system;
          config.allowUnfree = true;
          inherit overlays;
        };
        userSettings = {
          username = host.username;
          editor = "nvim";
          config-location = "~/nix-config";
          local_agent_knowledge_dir = "~/.local/share/agent-knowledge";
          enable-ai-workflow = true;
          enable-agent-tracker = true;
          enable-pi-agent = true;
          enable-neovim = true;
          enable_bash_over_zsh = false;
          import-extras = true;
          sessionizerSearchPaths = [ "~" "~/projects/nix" ];
          ai_features = {
            enable_ai_ssa_creator_skill = false;
            enable_tmux_based_agent_comms = true;
            enable_agent_knowledge = false;
            enable_home_manager_skill = false;
          };
        };
      in {
        inherit name;
        value = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit host userSettings;
            inputs = inputs // home-manager-core.inputs;
          };
          modules = [
            ./hosts/${name}/home.nix
            home-manager-core.homeManagerModules.default
            extensions.homeManagerModules.ai-agents
            extensions.homeManagerModules.tasks
            heimdall.homeModules.default
            ({ lib, ... }: {
              home.username = host.username;
              home.homeDirectory = host.homeDirectory;
              home.stateVersion = lib.mkForce "25.11";
            })
          ];
        };
      }
    ) [ "dragonfly" "zephyrus" "dawnstar" ]);
  };
}
