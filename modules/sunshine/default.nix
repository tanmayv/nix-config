{ pkgs, ...}: {
  services.sunshine = {
    enable = true;
    autoStart = true; 
    capSysAdmin = true; # true if using wayland
    openFirewall = true;
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # your Open GL, Vulkan and VAAPI drivers
      vpl-gpu-rt # for newer GPUs on NixOS &gt;24.05 or unstable
      # onevpl-intel-gpu  # for newer GPUs on NixOS &lt;= 24.05
      # Below was required for intel Arc GPU's
      # intel-media-driver
      # intel-media-sdk   # for older GPUs
    ];
  };
  boot.kernelParams = [ "i915.force_probe=46a8" ];
}
