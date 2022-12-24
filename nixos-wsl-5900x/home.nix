{ config, pkgs, ... }:

# BROKEN, TODO: FIX

with config; {

  home.packages = with pkgs; [
    wslu
    wsl-open
  ];

}
