# repl-env.nix
let
  flake = builtins.getFlake (toString ./flake.nix);
  nixpkgs = flake.inputs.nixpkgs;
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  lib = pkgs.lib;
in
{
  inherit lib pkgs;
  mod = import ./modules/core/lib/helper/default.nix { inherit lib pkgs; config = {}; };
}

