{ config, pkgs, user, configName, lib, ... }:
let

  exts = with pkgs.gnomeExtensions; [
    astra-monitor
    cronomix
  ];

in
with config; {
  home.packages =
    exts ++
    (with pkgs; [
      # for astra-monitor
      pciutils
    ]);

  dconf = {
    enable = true;

    settings."org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = map (x: x.extensionUuid) exts;
    };

    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

    settings."settings-daemon/plugins/power" = {
      power-button-action = "nothing";
      sleep-inactive-ac-type = "nothing";
    };
  };
}
