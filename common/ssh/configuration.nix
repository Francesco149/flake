{ user, ... }:
let
  consts = import ../consts.nix;
  inherit (consts.ssh) authorizedKeys;
in
{
  users.users.${user}.openssh.authorizedKeys.keys = authorizedKeys;
  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;
  services.openssh.enable = true;

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      22
    ];
  };
}
