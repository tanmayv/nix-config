{ lib, pkgs, config, host, helper, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.apps.nvimPure;
in {
  options.apps.nvimPure = {
    enable = mkEnableOption "Pure NixOS Neovim setup with Lua config symlink";

    package = mkOption {
      type = types.package;
      default = pkgs.neovim;
      description = "Neovim package to install system-wide.";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [ ripgrep fd ];
      example = with pkgs; [ ripgrep fd ];
      description = "Extra CLI tools available to Neovim.";
    };

    setAsDefault = mkOption {
      type = types.bool;
      default = true;
      description = "Set EDITOR/VISUAL to nvim for all users.";
    };

    aliases = mkOption {
      type = types.bool;
      default = true;
      description = "Add vi/vim aliases that point to nvim (system-wide).";
    };
  };

  config = mkIf cfg.enable {
    # Install nvim and helper tools
    environment.systemPackages = [ cfg.package ] ++ cfg.extraPackages;

    # Global EDITOR/VISUAL (optional)
    environment.variables = mkIf cfg.setAsDefault {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    # vi/vim aliases -> nvim (system-wide shells)
    environment.shellAliases = mkIf cfg.aliases {
      vi = "nvim";
      vim = "nvim";
    };

    # Create the ~/.config dir (if missing) and the ~/.config/nvim symlink for each user
    # systemd.tmpfiles.rules = helper.mkDotfiles host.username ".config" "nvim" ./dotfiles;
    systemd.tmpfiles.rules = helper.mkTmpFileRules host.username ".config/nvim" ./dotfiles;
  };
}

