{ config, ... }:
with config; {

  imports = [../home.nix ];

  home.packages = with pkgs; [
    wslu
    wsl-open
  ];

}
