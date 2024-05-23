{ config, pkgs, user, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/desktop/configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;

  # the hdmi switch freaks out if I boot at low res and then switch res
  boot.loader.systemd-boot.consoleMode = "max";

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  boot.initrd.luks.devices."luks-d654e001-13da-4c87-8a5d-28597e1a9199".device = "/dev/disk/by-uuid/d654e001-13da-4c87-8a5d-28597e1a9199";
  boot.initrd.luks.devices."luks-d654e001-13da-4c87-8a5d-28597e1a9199".keyFile = "/crypto_keyfile.bin";


  networking = {
    hostName = "tanuki";
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # secrets

  # by default, agenix does not look in your home dir for keys
  age.identityPaths = [
    "/root/.ssh/id_rsa"
  ];

  # agenix secrets are owned by root and symlinked from /run/agenix.d .
  # to have user-owned secrets I have to disable symlinking and make sure the ownership is correct
  # TODO: don't hardcode barrier folder
  age.secrets = {

    barrierc-private-key = {
      file = ../secrets/barrier/BarrierTanuki.pem.age;
      path = "/home/${user}/.local/share/barrier/SSL/Barrier.pem";
      symlink = false;
      owner = "loli";
    };

  };

  system.stateVersion = "22.11";

}
