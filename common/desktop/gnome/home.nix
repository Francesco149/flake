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
    settings."org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Shift><Super>u";
      command = "${pkgs.pass}/bin/passmenu";
      name = "passmenu";
    };

    settings."org/gnome/desktop/background" = {
      picture-uri = "${xdg.dataHome}/wallpaper.png";
    };
  };
}
