{pkgs, config, host, lib, helper, ...}: {
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
      command = "${pkgs.tuigreet}/bin/tuigreet --remember --time --cmd 'niri-session'";
    };
  };

   # XDG portals
  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-wlr  # Wayland-native (for screen sharing, screenshots, etc.)
    xdg-desktop-portal-gtk  # Nice GTK file chooser dialogs
  ];
  # PAM auth for gtklock
  security.pam.services.gtklock = {};
  systemd.tmpfiles.rules = helper.mkTmpFileRules host.username ".config/niri" ./dotfiles;
}
