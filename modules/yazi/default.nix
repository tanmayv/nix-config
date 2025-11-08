{ pkgs, host, ... }: {
  environment.systemPackages = with pkgs; [
    yazi
    fzf
  ];
}
