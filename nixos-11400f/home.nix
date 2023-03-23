{ config, pkgs, ... }:
let

in with config; {

  imports = [
    ../common/desktop/home.nix
  ];

  home.packages = (with pkgs; [
    discord
  ]);

  home.stateVersion = "22.05";

}
