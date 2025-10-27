{ lib, pkgs, config, host, helper, ... }:

let
  vmName = "proxmox-backup";
  isoUrl = "https://enterprise.proxmox.com/iso/proxmox-backup-server_3.2-1.iso";
  isoPath = "/var/lib/libvirt/isos/proxmox-backup-server.iso";
  diskPath = "/var/lib/libvirt/images/proxmox-backup.qcow2";
  ram = 4096;    # MB
  vcpus = 2;
  diskSizeGiB = "300G";
  cfg = config.myservice.pbs-vm;
  dotfilesPath = builtins.path {
    path = cfg.configSrcPath;
    name = "virtmanage-dotfiles";
  };
in
{
  options.myservice.pbs-vm = {
    enable = lib.mkEnableOption "Enable the bootstrap script";

    isoUrl = lib.mkOption {
      type = lib.types.str;
      description = "URL to the Proxmox Backup Server ISO to download.";
    };

    isoName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Optional filename to save the ISO as. If null, derived from isoUrl basename.";
      default = null;
    };

    isoDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory to store the ISO.";
      default = "/var/lib/libvirt/isos";
    };

    sha256 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Optional sha256 checksum (hex). If set, verify after download.";
      default = null;
    };

    # VM parameters
    vmName = lib.mkOption {
      type = lib.types.str;
      default = "pbs-vm";
      description = "Name of the libvirt domain to create.";
    };

    memoryMB = lib.mkOption {
      type = lib.types.int;
      default = 4096;
      description = "Memory in MB for the VM.";
    };
    vcpus = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Number of vCPUs for the VM.";
    };
    diskSizeGB = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "Disk size in GB for the VM's qcow2 disk.";
    };
    diskDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/libvirt/images";
      description = "Directory to create VM disk files in.";
    };

    # Network (libvirt network name, e.g. 'default' or a bridge)
    vmBridge = lib.mkOption {
      type = lib.types.str;
      default = "pbsbr0";
      description = "Bridge interface name for pbs";
    };

    # Extra virt-install args (optional string appended to command)
    extraVirtInstallArgs = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Extra arguments appended to virt-install invocation.";
    };
  };

  config = lib.mkIf cfg.enable {

    # Enable libvirt and virt-manager (optional)
    virtualisation.libvirtd = {
      enable = true;
    };

    # Provide virt-install and wget in the system profile so activation script can run
    environment.systemPackages = with pkgs; [
      virt-manager         # optional, provides virt-install, virt-viewer UI
      virt-viewer         # optional, provides virt-install, virt-viewer UI
      qemu                 # qemu
      libvirt              # libvirt client tools
      wget                 # to fetch ISO

    (pkgs.writeShellScriptBin "pbs.download-iso" ''
        #!/usr/bin/env bash
        set -euo pipefail

        ISO_URL='${cfg.isoUrl}'
        ISO_DIR='${cfg.isoDir}'
        ISO_NAME=${if cfg.isoName == null then "''${builtins.baseNameOf cfg.isoUrl}" else "\"${cfg.isoName}\""}
        CHECKSUM='${cfg.sha256}'

        WGET="${pkgs.wget}/bin/wget"
        SHA256SUM="${pkgs.coreutils}/bin/sha256sum"
        MKDIR="${pkgs.coreutils}/bin/mkdir"
        MV="${pkgs.coreutils}/bin/mv"
        MKTEMP="${pkgs.coreutils}/bin/mktemp"

        # Root check
        if [ "$(id -u)" -ne 0 ]; then
          echo "This script must be run as root (or via sudo)." >&2
          exit 1
        fi

        if [ -z "$ISO_URL" ]; then
          echo "ERROR: No isoUrl configured (set config.my.bootstrap.isoUrl)" >&2
          exit 2
        fi

        if [ ! -d "$ISO_DIR" ]; then
          echo "Creating directory $ISO_DIR"
          $MKDIR -p "$ISO_DIR"
          chmod 755 "$ISO_DIR"
        fi

        ISO_PATH="$ISO_DIR/$ISO_NAME"

        if [ -f "$ISO_PATH" ]; then
          echo "✅ ISO already exists at $ISO_PATH"
          exit 0
        fi

        echo "📦 Downloading ISO from $ISO_URL..."
        tmpfile=$($MKTEMP --tmpdir iso.XXXXXX)
        trap 'rm -f "$tmpfile"' EXIT

        # wget options:
        #   -c : continue partial downloads
        #   -O : output to file
        #   --tries : retry up to 5 times
        #   --progress=bar:force : progress bar
        $WGET -c -O "$tmpfile" --tries=5 --progress=bar:force "$ISO_URL"

        if [ -n "$CHECKSUM" ] && [ "$CHECKSUM" != "null" ]; then
          echo "🔍 Verifying SHA256 checksum..."
          echo "$CHECKSUM  $tmpfile" | $SHA256SUM -c - \
            || { echo "❌ Checksum verification failed!"; exit 4; }
        fi

        $MV "$tmpfile" "$ISO_PATH"
        chmod 644 "$ISO_PATH"
        echo "✅ ISO downloaded to $ISO_PATH"
    '')

    (pkgs.writeShellScriptBin "pbs.cleanup" ''

        #!/usr/bin/env bash
        set -euo pipefail
        VIRSH='${pkgs.libvirt}/bin/virsh'
        VM_NAME='${cfg.vmName}'

        # Root check
        if [ "$(id -u)" -ne 0 ]; then
          echo "This script must be run as root (or via sudo)." >&2
          exit 1
        fi

        $VIRSH destroy $VM_NAME
        $VIRSH undefine $VM_NAME --nvram
    '')
    (pkgs.writeShellScriptBin "pbs.bootstrap" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # -------- Nix-injected config --------
        ISO_DIR='${cfg.isoDir}'
        ISO_NAME='${cfg.isoName}'
        VM_NAME='${cfg.vmName}'
        MEM_MB='${toString cfg.memoryMB}'
        VCPUS='${toString cfg.vcpus}'
        DISK_SIZE_GB='${toString cfg.diskSizeGB}'
        DISK_DIR='${cfg.diskDir}'
        EXTRA_ARGS='${cfg.extraVirtInstallArgs}'
        # ------------------------------------

        VIRT_INSTALL='${pkgs.virt-manager}/bin/virt-install'
        QEMU_IMG='${pkgs.qemu_kvm}/bin/qemu-img'
        VIRSH='${pkgs.libvirt}/bin/virsh'
        # helper tools
        MKDIR='${pkgs.coreutils}/bin/mkdir'
        SYSTEMCTL='/run/current-system/sw/bin/systemctl' # systemctl from Nix (on NixOS)
        CHMOD='${pkgs.coreutils}/bin/chmod'
        MV='${pkgs.coreutils}/bin/mv'
        ECHO='${pkgs.coreutils}/bin/echo'
        TEST='${pkgs.coreutils}/bin/test'

        # Root check
        if [ "$(id -u)" -ne 0 ]; then
          echo "This script must be run as root (or via sudo)." >&2
          exit 1
        fi

        # ensure libvirtd running; try to start it if not
        if ! $SYSTEMCTL is-active --quiet libvirtd.service; then
          echo "libvirtd.service is not active. Attempting to start it..."
          if ! $SYSTEMCTL start libvirtd.service; then
            echo "Failed to start libvirtd.service. Enable it in NixOS (services.libvirtd.enable = true) or start manually." >&2
            exit 6
          fi
          # small wait so libvirt sockets show up
          sleep 1
        fi


        ISO_PATH="$ISO_DIR/$ISO_NAME"
        if [ ! -f "$ISO_PATH" ]; then
          echo "ERROR: ISO not found at $ISO_PATH" >&2
          exit 2
        fi

        # If domain already exists, do nothing
        if $VIRSH dominfo "$VM_NAME" >/dev/null 2>&1; then
          echo "VM '$VM_NAME' already exists. Exiting."
          exit 0
        fi

        # Ensure disk directory exists
        if [ ! -d "$DISK_DIR" ]; then
          echo "Creating disk directory $DISK_DIR"
          $MKDIR -p "$DISK_DIR"
          $CHMOD 755 "$DISK_DIR"
        fi

        DISK_PATH="$DISK_DIR/$VM_NAME.qcow2"
        echo "Creating qcow2 disk at $DISK_PATH (''${DISK_SIZE_GB}G)..."
        $QEMU_IMG create -f qcow2 "$DISK_PATH" "''${DISK_SIZE_GB}G"

        # Build virt-install command
        echo "Running virt-install to create VM '$VM_NAME'..."
        # Use --noautoconsole so the script doesn't hang attaching console.
        $VIRT_INSTALL \
          --name $VM_NAME \
          --ram $MEM_MB \
          --vcpus $VCPUS \
          --os-variant detect=on \
          --disk path="$DISK_PATH",format=qcow2,bus=virtio \
          --cdrom "$ISO_PATH" \
          --network bridge=${cfg.vmBridge},model=virtio \
          --graphics spice \
          --osinfo detect=on,name=linux2024 \
          --boot uefi,hd,cdrom \
          $EXTRA_ARGS || {
            echo "virt-install failed." >&2
            exit 3
          }

        echo "VM '$VM_NAME' created (or started)."
        echo "You can inspect it with: $VIRSH list --all | grep $VM_NAME"
        echo "To attach console: virsh console $VM_NAME"
      '')
    ];

    users.users.${host.username} = lib.mkIf true {   # adjust user name as needed
      extraGroups = [ "libvirtd" "kvm" ];
    };

    # Ensure directories exist with correct ownership
    systemd.tmpfiles.rules = (helper.mkDotfiles host.username ".config" "virt-manager" ./dotfiles)
    ++ [
      "d /var/lib/libvirt/isos 0755 root root - -"
      ("f " + isoPath + " 0644 root root - -") # this just ensures parent dir exists; file created later
      "d /var/lib/libvirt/images 0755 root root - -"
    ];


  };

}
