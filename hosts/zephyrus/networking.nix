{ config, host, ... }:{
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

  sops.secrets."wireguard/zephyrus_private_key" = { };

  networking.wg-quick.interfaces.zephyrus = {
    address = [ "10.80.0.6/24" ];
    dns = [ "10.27.0.1" ];
    privateKeyFile = config.sops.secrets."wireguard/zephyrus_private_key".path;
    peers = [
      {
        publicKey = "2DCLtfnsr8EQCEUgODMU99KkzbHvORUQDbkeUB9lygg=";
        allowedIPs = [
          "10.80.0.0/24"
          "10.27.0.0/24"
          "192.168.0.0/24"
        ];
        endpoint = "66.116.207.238:51820";
        persistentKeepalive = 25;
      }
    ];
  };

  hardware.bluetooth.enable = true;

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNSSEC = "false";
        FallbackDNS = [];
        DNSOverTLS = "false";
      };
    };
  };

  users.users.${host.username} = {
    extraGroups = [ "networkmanager" ];
  };
}

