{ ... }:
{
  imports = [
    # nixos-generate-config --show-hardware-config > hardware-configuration.nix
    ./hardware-configuration.nix
    ../../common/nix/configuration.nix
    ../../common/mitigations/configuration.nix
    ../../common/locale/configuration.nix
    ../../common/ssh/configuration.nix
    ../../common/hosts/configuration.nix
    ../../common/autologin/configuration.nix
  ];
}
