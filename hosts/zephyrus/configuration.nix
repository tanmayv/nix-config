# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, host, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ../../modules/neovim/default.nix
      # ../../modules/pbs-vm/default.nix
      ../../modules/git/default.nix
      ../../modules/ghostty/default.nix
      ../../modules/apollo/default.nix
      ../../modules/gpg-yubi-ssh/default.nix
      ../../modules/xr/default.nix
      ../../modules/yazi/default.nix
      ../../modules/zsh/default.nix
      ../../modules/tmux/default.nix
      ../../modules/atuin/default.nix
      ../../modules/desktop-env/niri/default.nix
      ../../modules/desktop-env/hyprland/default.nix
      # ../../modules/desktop-env/plasma/default.nix
      ../../modules/steam/default.nix
      ./networking.nix
      ./graphics.nix
      ./packages.nix
      ./drivers.nix
      ./hardware-configuration.nix
    ];

  virtualisation.docker.enable = true;
  virtualisation.docker.extraPackages = [ pkgs.docker-buildx ];
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };
  environment.systemPackages = with pkgs; [
    virt-manager
    audacity
  ];

  stylix.enable = true ;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-frappe.yaml";

  # myservice.pbs-vm = {
  #   enable = true;
  #   isoUrl = "https://enterprise.proxmox.com/iso/proxmox-backup-server_4.0-1.iso";
  #   isoName = "proxmox-backup-server_4.0-1.iso";
  #   sha256 = "208607b250164863b5731a29dd89569a123e6f385c5ec0939a4942357bf731e2";
  #   vmBridge = "pbsbr0";
  # };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.tailscale = {
    enable = true;         # Enables tailscaled system service
    useRoutingFeatures = "client";  # "none", "client", or "server"
    openFirewall = true;   # Automatically open firewall for Tailscale
  };


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

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [ 
      nerd-fonts.victor-mono
      ubuntu_font_family
      liberation_ttf
      # Persian Font
      vazir-fonts
    ];

    fontconfig = {
      defaultFonts = {
        serif = [  "Liberation Serif" "Vazirmatn" ];
        sansSerif = [ "Ubuntu" "Vazirmatn" ];
        monospace = [ "Victor Mono" ];
      };
    };
  };
  

  # Set your time zone.
  time.timeZone = host.timezone;
  # Also apply the same mapping on virtual consoles (tty1, tty2, …)
  console.useXkbConfig = true;

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";

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
