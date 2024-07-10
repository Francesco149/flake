{ config, pkgs, user, configName, lib, ... }:
with config; {
  imports = [
    ../../common/gnome/home.nix
    ../../common/xterm/home.nix
    ../../common/vim/home.nix
  ];

  home.username = "${user}";
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "24.05";
}
