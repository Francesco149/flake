{ config, pkgs, user, configName, lib, ... }:
let

  exts = with pkgs.gnomeExtensions; [
    astra-monitor
    cronomix
  ];

in
with config; {

  home.packages = exts;

  dconf = {
    enable = true;

    settings."org/gnome/mutter".dynamic-workspaces = true;

    settings."org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = map (x: x.extensionUuid) exts;

      favorite-apps = [
        "firefox.desktop"
        "xterm.desktop"
        "org.gnome.Nautilus.desktop"
        "armcord.desktop"
        "org.telegram.desktop.desktop"
        "org.gnome.TextEditor.desktop"
      ];
    };

    settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      clock-show-weekday = true;
    };

    settings."org/gnome/settings-daemon/plugins/power" = {
      power-button-action = "nothing";
      sleep-inactive-ac-type = "nothing";
    };
  };

}
