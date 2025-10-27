{host, ... }:{
  networking.resolvconf.enable = false; # Otherwise, dns is overriden
  networking.search = [ "local.lan" ]; # Otherwise, dns is overriden
  networking.useNetworkd = false;
  networking.networkmanager.unmanaged = [ host.eth-interface ];
  networking.networkmanager.enable = true;
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networking.hostName = host.hostname; # Define your hostname.

    networking.nameservers = [
    "192.168.0.1"
    ];

  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;
  systemd.network = {
    netdevs = {
      # Create the bridge interface
      "10-pbsbr0" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "pbsbr0";
        };
      };
    };
    networks = {
      # Connect the bridge ports to the bridge
      "20-pbsbr0-en" = {
        matchConfig.Name = "en*";
        networkConfig.Bridge = "pbsbr0";
      };
      # Configure the bridge for its desired function
      "20-pbsbr0" = {
        matchConfig.Name = "pbsbr0";
        networkConfig.DHCP = "yes";
        linkConfig = {
          RequiredForOnline = "routable";
        };
      };
    };
  };


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

