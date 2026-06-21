{ config, host, pkgs, ... }:{
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

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;

  # The onboard MediaTek Bluetooth adapter can disappear from BlueZ after
  # rfkill/autosuspend, leaving blueman with "Adapter is None".
  boot.extraModprobeConfig = ''
    options btusb reset=1 enable_autosuspend=0
  '';

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0489", ATTR{idProduct}=="e0f6", TEST=="power/control", ATTR{power/control}="on"
  '';

  systemd.services.rfkill-unblock-bluetooth = {
    description = "Unblock Bluetooth rfkill before starting bluetoothd";
    before = [ "bluetooth.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
    };
  };

  systemd.services.bluetooth = {
    wants = [ "rfkill-unblock-bluetooth.service" ];
    after = [ "rfkill-unblock-bluetooth.service" ];
  };

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

