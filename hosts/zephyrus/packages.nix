{ pkgs, nixpkgs, ... }: {
  
# nixpkgs.config = {
#   packageOverrides = pkgs: {
#     bambu-studio = pkgs.bambu-studio.overrideAttrs (oldAttrs: {
#       version = "01.00.01.50";
#       src = pkgs.fetchFromGitHub {
#         owner = "bambulab";
#         repo = "BambuStudio";
#         rev = "v01.00.01.50";
#         hash = "sha256-7mkrPl2CQSfc1lRjllilwxdYcK5iRU//QGKmdCick30=";
#       };
#     });
#   };
# };
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
    freecad
  ];
}
