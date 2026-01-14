{ config, pkgs, host, ... }: {
# Allow unfree packages
  services.openssh = {
    enable = true;
  };
  nix.settings.trusted-users = ["tanmay"];
  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
      '';
  };

  sops = {
    defaultSopsFile = ../../secrets/trusted/personal.yaml;

    age = {
      keyFile = "${host.homeDirectory}/.config/sops/age/trusted_host.txt";
      generateKey = false;
    };

    secrets = {
      "ssh/authorized_keys" = {
        path = "${host.homeDirectory}/.ssh/authorized_keys";
        mode = "0644";
      };
      "ssh/yubi_pub" = {
        path = "${host.homeDirectory}/.ssh/yubikey.pub";
        mode = "0644";
      };
      "user_private_key" = {
        owner = "${host.username}";
      };
      "API_KEYS/GEMINI_API_KEY" = {
        owner = "${host.username}";
      };
    };
  };
  # Create a helper file that exports the variable
  sops.templates."gemini-secret.env" = {
    content = ''
      export GEMINI_API_KEY="${config.sops.placeholder."API_KEYS/GEMINI_API_KEY"}"
      '';
  };
  programs.ssh.extraConfig = ''
    Host *
      IdentityFile ${config.sops.secrets.user_private_key.path}
  '';
  # Source it in your shell so Neovim inherits it
  programs.zsh.interactiveShellInit = ''
    export GEMINI_API_KEY=$(cat ${config.sops.secrets."API_KEYS/GEMINI_API_KEY".path})
  '';
}
