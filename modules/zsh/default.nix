{ pkgs, helper, host, ... }: {
  programs.starship = {
    enable = true;
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

    shellAliases = {
      ll = "ls -l";
      edit = "sudo -e";
      update = "sudo nixos-rebuild switch --flake $HOME/nix-config#${host.hostname}";
    };

    histSize = 10000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
    ];
  };


  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  users.defaultUserShell = pkgs.zsh;
}
