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
  # TODO: do not hardcode this home path, get it from home-manager somehow or something
  age.identityPaths = [
    "/home/${user}/.ssh/id_rsa"
  ];

  # agenix secrets are owned by root and symlinked from /run/agenix.d .
  # so to have user-owned secrets I have to disable symlinking and make sure the ownership is correct
  age.secrets =
    let

      mkUserSecret = { file, path }: {
        inherit file path;
        owner = "${user}";
        group = "users";
        symlink = false;
      };

      secretPath = path: "/var/lib/${user}-secrets/${path}";

    in
    {

      barrierc-private-key = mkUserSecret {
        file = ../../secrets/barrier/BarrierTanuki.pem.age;
        path = "/home/${user}/.local/share/barrier/SSL/Barrier.pem";
      };

      gh2md-token = mkUserSecret {
        file = ../../secrets/gh2md/token.age;
        path = "/home/${user}/.config/gh2md/token";
      };

      gist-token = mkUserSecret {
        file = ../../secrets/gist/token.age;
        path = "/home/${user}/.gist";
      };

      # TODO: make it so chatterino can refresh its token every month.
      #       the file gets replaced at every boot if i enable this.
      #chatterino-settings = mkUserSecret {
      #  file = ../../secrets/chatterino/settings.json.age;
      #  path = "/home/${user}/.local/share/chatterino/Settings/settings.json";
      #};

      protonvpn-creds = mkUserSecret {
        file = ../../secrets/protonvpn/creds.txt.age;
        path = "/home/${user}/.local/share/protonvpn/creds.txt";
      };

      protonvpn-conf = mkUserSecret {
        file = ../../secrets/protonvpn/config.ovpn.age;
        path = "/home/${user}/.local/share/protonvpn/config.ovpn";
      };

    };

  system.stateVersion = "22.11";

}
