{ pkgs, ... }: {
  boot.kernelModules = [ "asus-nb-wmi" ];
  # Allow all users to update brightness
  services.udev.extraRules = ''
  ACTION=="add", SUBSYSTEM=="leds", KERNEL=="*kbd_backlight*", MODE="0666"
  '';
  environment.systemPackages = [ pkgs.brightnessctl ];

  # flake or configuration.nix
  services.power-profiles-daemon.enable = true;   # KDE/GNOME use this too
  services.upower.enable = true;                  # battery stats for tools
}
