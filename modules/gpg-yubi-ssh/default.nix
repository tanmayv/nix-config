{ config, helper, pkgs, host, lib, ...}:
{
  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    settings = {
      interactive = true;
      cue = true;
      origin = "pam://yubi";
      authfile = pkgs.writeText "u2f-mappings" (lib.concatStrings [
        "tanmay"
        ":MiF3UotqzvWHGOepVNQOlU4tmccudDIaEcMebPSzAtqSywm2Qt1s5FJVPIFydVMCq8jDrviWzBVIdUrFBP6jmA==,JeSHDSKFve2aMQbLwbT1OAHN61A9KddoWnUJJKIjYuNefi4J4QH5FkGfiMq/M+cJlRZeus02O8RLpsVxXwFKsw==,es256,+presence"
        ":HCGrdNR4imbt+RYdJmMGZ+ekilLDKdqqXZ7gLESnDEVlzFvyRC1amHlrVoxrZuhfmJGDRh9BlaWrX4XC6zJsOA==,q4TluS+86D7LHiAqEOs8u3pgMpFCdB/1egpQ3JMla9gqBD1RV4ogdsJt2WdJg9AjxPbFJuGNoCHW/hPPnUklpQ==,es256,+presence"
        ":CZoZ8akYavJ3XjKuhi3lr89V/QgCuXl70FrwRg4dHA24l37LJqXpshkuqK01c/+Hbkq38WjVA1amygeqh8Cu3A==,YwoDDq60jVrfrJ1RhVWumwRX5MaqZkGuNXafHBxJrHlZFK2etIgH6tUOOYKG0fBH+8Mvy715IzreeiqkkFepLQ==,es256,+presence"
      ]);
    };
  };

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };


  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # IMPORTANT: disable ccid to prevent conflict with pcscd and gpg-agent
  # echo "disable-ccid" > ~/.gnupg/scdaemon.conf


  services = {
    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization ];
  };


  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "gpg.enc" ''
        #!/usr/bin/env bash
        set -euo pipefail

        PRIMARY_YUBI_KEY=0x15EE62E8D21043C2
        ENC_FILE_NAME="''${1}.gpg"
        gpg -e \
        -r $PRIMARY_YUBI_KEY \
        -o $ENC_FILE_NAME $1
    '')
    (pkgs.writeShellScriptBin "gpg.encdir" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Base directory (default: current directory)
        base_dir="''${1:-.}"

        # Find all non-hidden regular files recursively
        find "$base_dir" \
          -type f \
          ! -path '*/.*' \
          -exec bash -c '
            for file; do
              echo "Encrypting: $file"
              gpg.enc "$file"
            done
          ' bash {} +
    '')

  ];

  systemd.tmpfiles.rules = helper.mkTmpFileRules host.username ".gnupg" ./dotfiles;
  # systemd.tmpfiles.rules = (helper.mkDotfiles host.username "" ".gnupg-test" ./dotfiles) ++ (helper.mkTmpFileRules host.username ".gnupg" ./dotfiles);
}
