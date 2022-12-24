{ config, ... }:
let

in with config; {

  imports = [
    ../common/desktop/home.nix
  ];

}
