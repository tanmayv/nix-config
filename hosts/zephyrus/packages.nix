{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    obsidian
    codex
    gemini-cli
    tmux
    ticktick
  ];
}
