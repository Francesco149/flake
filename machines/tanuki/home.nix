{ config, ... }:
let
  consts = import ../../common/consts.nix;

in with config; {

  imports = [
    ../../common/desktop/home.nix
  ];

  services.barrier.client = {
    enable = true;
    server = consts.machines.streampc-5900x.ip;
    enableDragDrop = true;
  };

  xdg.dataFile = {
    # TODO: for some reason it's not able to mkdir this so I have to manually create it
    "barrier/SSL/Fingerprints/TrustedServers.txt".source = ./barrier/TrustedServers.txt;
    "chatterino/Settings/window-layout.json".source = ./chatterino/window-layout.json;
  };

  home.stateVersion = "22.11";

}
