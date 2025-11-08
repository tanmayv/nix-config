{pkgs, config, host, lib, ...}: {
  programs.niri.enable = true;
  environment.systemPackages = with pkgs; [
    imagemagick
    rofi
    waybar
    swww
    mako
    bibata-cursors
    jetbrains-mono
    material-symbols
    papirus-icon-theme
    xwayland-satellite
    gtklock
    swayidle
    btop
  ];

  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "greeter";
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --remember --time --cmd 'niri-session'";
    };
  };

   # XDG portals
  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-wlr  # Wayland-native (for screen sharing, screenshots, etc.)
    xdg-desktop-portal-gtk  # Nice GTK file chooser dialogs
  ];


  # Autostart swayidle with niri to auto-lock
  # environment.etc."niri.kdl".text = ''
  #   spawn "swayidle timeout 300 'gtklock -s' before-sleep 'gtklock -s'"
  #   bind "Super+L" { spawn "gtklock -s" }
  # '';
  #
    # PAM auth for gtklock
  security.pam.services.gtklock = {};


  # Ensure Power Management triggers lock on suspend
  # services.logind.extraConfig = ''
  #   HandleLidSwitch=suspend
  #   HandleLidSwitchDocked=ignore
  #   IdleAction=lock
  #   IdleActionSec=5min
  # '';
}
