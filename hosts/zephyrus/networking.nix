{host, ... }:{
  networking.networkmanager.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.hostName = host.hostname;
  networking.nameservers = [
    "192.168.0.1"
  ];

  hardware.bluetooth.enable = true;

  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = [];
    dnsovertls = "false";
  };

  users.users.${host.username} = {
    extraGroups = [ "networkmanager" ];
  };

             }

