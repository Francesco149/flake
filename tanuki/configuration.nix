{ config, pkgs, user, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/desktop/configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  boot.initrd.luks.devices."luks-d654e001-13da-4c87-8a5d-28597e1a9199".device = "/dev/disk/by-uuid/d654e001-13da-4c87-8a5d-28597e1a9199";
  boot.initrd.luks.devices."luks-d654e001-13da-4c87-8a5d-28597e1a9199".keyFile = "/crypto_keyfile.bin";


  networking = {
    hostName = "tanuki";
    networkmanager.enable = true;
  };

  system.stateVersion = "22.11";

}
