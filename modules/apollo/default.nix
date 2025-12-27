{ pkgs, config, host, helper, lib, apollo-flake,...}: 
let 
cfg = config.services.apollo;
apollo-pkg = apollo-flake.packages.${pkgs.system}.default;
hdmiHotplugScript = pkgs.writeShellScript "hdmi-a-1-hotplug" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    STATUS_FILE="/sys/class/drm/card2-HDMI-A-1/status"

    # Some GPUs might expose HDMI as HDMI-A-1, HDMI-A-2, etc.
    # Adjust the path above if needed after checking ls /sys/class/drm.
    if [[ ! -r "$STATUS_FILE" ]]; then
      ${pkgs.coreutils}/bin/logger -t hdmi-hotplug "Status file $STATUS_FILE not found"
      exit 0
    fi

    status="$(${pkgs.coreutils}/bin/cat "$STATUS_FILE" 3>/dev/null || echo unknown)"
    ${pkgs.coreutils}/bin/echo "Read status $status" >> /tmp/hdmi-log

    case "$status" in
      connected)
        ${pkgs.coreutils}/bin/echo "HDMI connected" >> /tmp/hdmi-log
        notify-send "Dummy Plug Connected"
        # ${pkgs.coreutils}/bin/logger -t hdmi-hotplug "HDMI-A-1 connected"
        ${pkgs.niri}/bin/niri msg output eDP-1 off

        # TODO: put your "HDMI connected" actions here
        # Example stub:
        ;;

      disconnected)
        ${pkgs.coreutils}/bin/echo "HDMI disconnected" >> /tmp/hdmi-log
        notify-send "Dummy Plug Disconnected"
        ${pkgs.niri}/bin/niri msg output eDP-1 on

        # TODO: put your "HDMI disconnected" actions here
        # Example stub:
        ;;

      *)
        ${pkgs.coreutils}/bin/logger -t hdmi-hotplug "Unknown HDMI-A-1 status: $status"
        ;;
    esac
  '';
  edidFileName = "samsung-q800t-hdmi2.1"; 
  videoPort = "HDMI-A-1";
in with lib; {
# # 1. Provide the EDID file to the kernel firmware search path
#   hardware.firmware = [
#     (pkgs.runCommand "custom-edid" {} ''
#       mkdir -p $out/lib/firmware/edid
#       cp ${./edid-files + "/${edidFileName}"} $out/lib/firmware/edid/${edidFileName}
#     '')
#   ];
#
# # {
# #   boot.kernelParams = [ "drm.edid_firmware=DP-2:edid/edid.bin" "video=DP-2:e" ];
# #   hardware.firmware = [
# #   (
# #     pkgs.runCommand "edid.bin" { } ''
# #       mkdir -p $out/lib/firmware/edid
# #       cp ${../custom-files/edid/edid.bin} $out/lib/firmware/edid/edid.bin
# #     ''
# #   )];
# # }
# # 3. Configure Kernel Parameters
#   boot.kernelParams = [
#     "drm.edid_firmware=${videoPort}:edid/${edidFileName}"
#     "video=${videoPort}:e"
#     "fbcon=map:0"
#   ];
#   boot = {
#     kernelPatches = [ {
#       name = "edid-loader-fix-config";
#       patch = null;
#       extraConfig = ''
#         FW_LOADER y
#         '';
#     } ];	
#   };
#

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
    # Run our script every time the DRM subsystem reports a hotplug
    ACTION=="change", SUBSYSTEM=="drm", ENV{HOTPLUG}=="1", RUN+="${hdmiHotplugScript}"
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
