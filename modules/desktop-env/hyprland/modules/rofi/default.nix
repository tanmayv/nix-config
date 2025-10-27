{ pkgs, helper, host, ... }: {

  environment.systemPackages = with pkgs; [
    tofi
  ];
}
