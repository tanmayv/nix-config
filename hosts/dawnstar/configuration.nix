# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, host, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ../../modules/neovim/default.nix
      ../../modules/git/default.nix
      ../../modules/apollo/default.nix
      ../../modules/ghostty/default.nix
      ../../modules/yazi/default.nix
      ../../modules/tmux/default.nix
      ../../modules/zsh/default.nix
      ../../modules/atuin/default.nix
      ../../modules/gpg-yubi-ssh/default.nix
      ../../modules/desktop-env/plasma/default.nix
      ./networking.nix
      ./hardware-configuration.nix
    ];

  stylix.enable = true ;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-frappe.yaml";
  # for remote build and switch
  security.sudo.wheelNeedsPassword = false;

  virtualisation.docker.enable = true;
  virtualisation.docker.extraPackages = [ pkgs.docker-buildx ];
  # virtualisation.libvirtd = {
  #   enable = true;
  #   qemu = {
  #     package = pkgs.qemu_kvm;
  #     runAsRoot = true;
  #     swtpm.enable = true;
  #   };
  # };
  # environment.systemPackages = with pkgs; [
  #   virt-manager
  # ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;




  apps.nvimPure = {
    enable = true;
    extraPackages = with pkgs; [ ripgrep fd ];
  };

  apps.ghostty = {
    enable = true;
    followWorkingTree = false;            # true = live updates, no rebuild
    setAsDefault = true;                  # optional
  };

  # Set your time zone.
  time.timeZone = host.timezone;
  # Also apply the same mapping on virtual consoles (tty1, tty2, …)
  console.useXkbConfig = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tanmay = {
    isNormalUser = true;
    description = "Tanmay";
    extraGroups = [ "wheel" "libvirtd" "docker"];
    packages = with pkgs; [
      
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
