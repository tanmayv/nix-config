{ pkgs, config, host, helper, lib, apollo-flake,...}: 
let 
cfg = config.services.apollo;
apollo-pkg = apollo-flake.packages.${pkgs.system}.default;
in with lib; {
  # services.sunshine = {
  #   enable = true;
  #   autoStart = false;
  #   capSysAdmin = true;
  #   openFirewall = true;
  #
  # };

  #  hardware.graphics = {
  #   enable = true;
  #   extraPackages = with pkgs; [
  #     # your Open GL, Vulkan and VAAPI drivers
  #     vpl-gpu-rt # for newer GPUs on NixOS &gt;24.05 or unstable
  #     # onevpl-intel-gpu  # for newer GPUs on NixOS &lt;= 24.05
  #     # Below was required for intel Arc GPU's
  #     # intel-media-driver
  #     # intel-media-sdk   # for older GPUs
  #   ];
  # };
  users.users.tanmay.extraGroups = [ "input" "video" "render" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    '';
  # Maybe for dragonfly?
  # boot.kernelParams = [ "i915.force_probe=46a8" ];
  # Nvidia only
  systemd.user.services.sunshine.serviceConfig.Environment = [
    "EGL_PLATFORM=wayland"
    "GBM_BACKEND=nvidia-drm"
    "__GLX_VENDOR_LIBRARY_NAME=nvidia"
    "__NV_PRIME_RENDER_OFFLOAD=1"
    "DRI_PRIME=1"
    # Optional, sometimes helps VA-API paths on NVIDIA
    "LIBVA_DRIVER_NAME=nvidia"
  ];
  # Enable self-hosted game streaming

  services.apollo = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
    # settings = {
    #   capture = "kms";
    # };
  };

  # systemd.services.apollo-alt = {
  #   description = "Second Apollo instance (custom args)";
  #   after = [ "network.target" "graphical.target" ];
  #   wants = [ "network.target" ];
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = ''
  #       ${pkgs.sunshine}/bin/apollo \
  #       --config /home/${host.username}/config/sunshine/sunshine_2.conf \
  #       '';
  #     Restart = "on-failure";
  #     User = "apollo";
  #   };
  #   wantedBy = [ "multi-user.target" ];
  # };

  # systemd.user.services.apollo-alt = {
  #     description = "Apollo - Self-hosted game stream host for Moonlight";
  #
  #     wantedBy = mkIf cfg.autoStart ["graphical-session.target"];
  #     partOf = ["graphical-session.target"];
  #     wants = ["graphical-session.target"];
  #     after = ["graphical-session.target"];
  #
  #     startLimitIntervalSec = 500;
  #     startLimitBurst = 5;
  #
  #     # Clear default PATH to ensure a controlled environment, especially for tray icon links
  #     environment.PATH = lib.mkForce null;
  #
  #     serviceConfig = {
  #       ExecStart = ''
  #       /run/wrappers/bin/apollo /home/${host.username}/.apollo/sunshine_2.conf
  #       '';
  #       Restart = "on-failure";
  #       RestartSec = "5s";
  #     };
  #   };

  environment.systemPackages = with pkgs; [ 
    (pkgs.writeShellScriptBin "apollo.start" ''
      #!/usr/bin/env bash
      set -euo pipefail

      apollo ~/.apollo/sunshine.conf &
      '')
    (pkgs.writeShellScriptBin "apollo.stop" ''
      #!/usr/bin/env bash
      set -euo pipefail
      ps aux | grep sunshine | awk "NR==1 {print ''$2}" | xargs kill


      LAPTOP_DISPLAY=$(niri msg outputs | grep eDP | sed -r "s/.*(eDP-[1|2]).*/\1/g")
      echo $LAPTOP_DISPLAY
      '')
    (pkgs.writeShellScriptBin "apollo.connect-ready" ''
      #!/usr/bin/env bash
      LAPTOP_DISPLAY=$(niri msg outputs | grep eDP | sed -r "s/.*(eDP-[1|2]).*/\1/g")
      echo $LAPTOP_DISPLAY

      niri msg output $LAPTOP_DISPLAY off && sleep $1 && niri msg output $LAPTOP_DISPLAY on

      '')
  ];


  hardware.xpadneo.enable = true; # XBOX one gamepad drivers 
    boot = {
      extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
      extraModprobeConfig = ''
        options bluetooth disable_ertm=Y
        '';
    };

  networking.firewall.enable = false;
  systemd.tmpfiles.rules = helper.mkTmpFileRules host.username ".apollo" ./dotfiles;
  # systemd.tmpfiles.rules = helper.mkTmpFileRules host.username ".config" ./dotfiles;
}
