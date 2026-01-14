{ pkgs, helper, host, ... }: 
let aliases = {
      ll = "ls -l";
      tree = "eza --icons --tree";
      ls = "eza --icons";
      edit = "sudo -e";
      update = "sudo nixos-rebuild switch --flake $HOME/nix-config#${host.hostname}";
      remote-update = "sudo nixos-rebuild switch --flake $HOME/nix-config#dawnstar --target-host tanmay@dawnstar.local.lan --sudo --ask-sudo-password";
    };
in
{
  environment.systemPackages = with pkgs; [
    eza
  ];
  environment.shellAliases = aliases;
  programs.starship = {
    enable = true;
  };
  programs.bash.enable = true;
  programs.bash.shellAliases = aliases;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "z"
      ];
      theme = "robbyrussell";
    };
    
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = aliases;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };
  users.defaultUserShell = pkgs.zsh;
}
