{ pkgs, host, helper, ... } : {
  # --- DISPLAY MANAGER: SDDM on Wayland ---
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # --- DESKTOP: Plasma 6 ---
  services.desktopManager.plasma6.enable = true;
  services.printing.enable = true;
   # Portals (screenshare, file pickers on Wayland, etc.)
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  # Optional: If you had the GNOME portal explicitly, remove it to avoid conflicts.
  # xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-kde pkgs.xdg-desktop-portal-gtk ];

  # (Optional) Input method frameworks on Wayland (if you need them):
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = [ pkgs.fcitx5-mozc pkgs.fcitx5-gtk ];
  };

  services.xserver.enable = true;                 # keep X available for apps, desktop runs Wayland
  hardware.opengl.enable = true;                  # 3D accel (Mesa/NVIDIA)

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Add config file for keyboard layout
  systemd.tmpfiles.rules = helper.mkTmpFileRules host.username ".config" ./dotfiles;
}

