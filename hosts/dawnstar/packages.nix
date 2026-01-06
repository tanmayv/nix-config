{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    gemini-cli
    tmux
    lazygit
    mpv
  ];
}
