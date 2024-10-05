{ config, pkgs, user, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/desktop/configuration.nix
    ../../common/i915/configuration.nix
  ];

  boot.initrd.luks.devices."luks-83b8c10a-431d-4a92-b9b5-26320303d2c0".device = "/dev/disk/by-uuid/83b8c10a-431d-4a92-b9b5-26320303d2c0";

  networking = {
    hostName = "tanuki";
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
      file = ../../secrets/barrier/BarrierTanuki.pem.age;
      path = "/home/${user}/.local/share/barrier/SSL/Barrier.pem";
      symlink = false;
      owner = "loli";
    };

  };

  system.stateVersion = "22.11";

}
