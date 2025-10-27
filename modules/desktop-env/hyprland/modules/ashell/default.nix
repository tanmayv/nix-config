{ pkgs, helper, host, ... } : {
  environment.systemPackages = with pkgs; [
    ashell
  ];
  systemd.tmpfiles.rules = helper.mkDotfiles host.username ".config" "ashell" ./dotfiles;
}
