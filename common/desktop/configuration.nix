# common configuration.nix for desktop machines

{ pkgs, user, ... }:
let
  consts = import ../../common/consts.nix;
in
{

  imports = [
    ../boot/configuration.nix
    ../users/configuration.nix
    ../limits/configuration.nix
    ../hosts/configuration.nix
    ../mitigations/configuration.nix
    ../locale/configuration.nix
    ../nix/configuration.nix
    ../gnome/configuration.nix
    ../dnscrypt/configuration.nix
    ../ssh/configuration.nix
    ../autologin/configuration.nix
    ../tablet/configuration.nix
    ../mouse/configuration.nix
  ];

  users.users.${user}.extraGroups = [ "networkmanager" "adbusers" ];
  programs.adb.enable = true;
  virtualisation.docker.enable = true;

  networking = {
    domain = "localhost";
    usePredictableInterfaceNames = false;
    networkmanager.enable = true;
  };

  programs.nm-applet.enable = true;
  programs.nix-ld.enable = true; # to run non-nixos bins

  hardware.bluetooth = {
    enable = true;

    # TODO: is this still doing anything?
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  services.blueman.enable = true;

  services.gvfs.enable = true; # for nautilus
  services.udisks2.enable = true; # to mount removable devices more easily
}
