{host, ... }:{
  networking.networkmanager.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.hostName = host.hostname;
  networking.nameservers = [
    "192.168.0.1"
  ];
  networking.extraHosts = 
    ''
    127.0.0.1 pos.app.local
    127.0.0.1 authentication.app.local
    172.27.20.50 pos-staging.app.local
    172.27.20.50 authentication-staging.app.local
    '';

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

