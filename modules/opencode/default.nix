
{ pkgs, ... }:

# let
#   # wrappedPackage = pkgs.symlinkJoin {
#   #   name = "wrapped-opencode";
#   #   paths = [ pkgs.opencode ]; # The original package
#   #   buildInputs = [ pkgs.makeWrapper ];
#   #   postBuild = ''
#   #     wrapProgram $out/bin/opencode \
#   #       --set MY_VAR "hello-world" \
#   #       --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.coreutils ]}
#   #   '';
#   # };
# in
{
  environment.systemPackages = with pkgs; [
    opencode 
  ];
}
