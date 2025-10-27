{ lib, pkgs, host, config, helper, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.apps.ghostty;

  # If followWorkingTree = false (default), copy config into the store (reproducible)

  # Pick the symlink target based on the chosen mode
  # targetPath =
  #   if cfg.followWorkingTree then cfg.configSrcPath else cfgSrcStore;
  #
  # mkRulesForUser = user:
  #   let home = "/home/${user}";
  #   in [
  #     # Ensure ~/.config exists
  #     "d ${home}/.config 0755 ${user} - - -"
  #     # Force (re)create ~/.config/ghostty -> targetPath
  #     "L+ ${home}/.config/ghostty - ${user} - - ${targetPath}"
  #   ];
in
{
  options.apps.ghostty = {
    enable = mkEnableOption "Ghostty terminal with config symlink";


    package = mkOption {
      type = types.package;
      default = pkgs.ghostty;
      description = "Ghostty package to install.";
    };

    # If true, symlink points directly to your working directory (no rebuild needed).
    # If false (default), the config is copied into the Nix store for reproducibility.
    followWorkingTree = mkOption {
      type = types.bool;
      default = false;
      description = ''
        When true, ~/.config/ghostty points directly at configSrcPath (live edits).
        When false, config is copied into the Nix store and requires rebuild to update.
      '';
    };

    setAsDefault = mkOption {
      type = types.bool;
      default = false;
      description = "Set TERMINAL=ghostty system-wide.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      [ cfg.package ];

    environment.variables = mkIf cfg.setAsDefault {
      TERMINAL = "ghostty";
    };

    # Create ~/.config and the ghostty symlink for each listed user
    systemd.tmpfiles.rules = helper.mkDotfiles host.username ".config" "ghostty" ./dotfiles;
  };
}

