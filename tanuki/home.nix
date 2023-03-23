{ config, ... }:
let

in with config; {

  imports = [
    ../common/desktop/home.nix
  ];

  home.stateVersion = "22.11";

}
