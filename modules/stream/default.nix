{ config, pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    vlc
    easyeffects
    kitty
    bat
    taskwarrior3
    taskwarrior-tui
  ];

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;

    # optional Nvidia hardware acceleration
    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
        browserSupport = true;
      }
    );

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      distroav
      droidcam-obs
      obs-shaderfilter
      obs-gstreamer
      obs-vkcapture
      obs-retro-effects
      obs-advanced-masks
      obs-aitum-multistream
    ];
  };
}
