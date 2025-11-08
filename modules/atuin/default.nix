
{ pkgs, helper, lib, host, ... }: {
  environment.systemPackages = with pkgs; [
    atuin
  ];

  programs.zsh.interactiveShellInit = lib.mkAfter ''
    # Bind ctrl-r but not up arrow
    eval "$(atuin init zsh --disable-up-arrow)"
  '';
  systemd.tmpfiles.rules = helper.mkTmpFileRules host.username ".config/atuin" ./dotfiles;
}

