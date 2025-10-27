{ hyprland, pkgs, helper, host, ... }:
{

  imports = [
    hyprland.nixosModules.default
    ./modules/rofi/default.nix
    ./modules/ashell/default.nix
  ];

  programs.hyprland.enable = true; # enable Hyprland
  # Optional, hint Electron apps to use Wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  systemd.tmpfiles.rules = helper.mkDotfiles host.username ".config" "hypr" ./dotfiles;

  environment.systemPackages = with pkgs; [
    jq
    mako
    wofi
    kdePackages.dolphin
    networkmanagerapplet
    pavucontrol
    wdisplays # gui
    wlr-randr # cli
    libnotify
  ];
  services.blueman.enable = true;
}
