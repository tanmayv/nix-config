{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    obsidian
    codex
    gemini-cli
    tmux
    gimp
    lazygit
    spotify
    ticktick
    mpv
  ];
}
