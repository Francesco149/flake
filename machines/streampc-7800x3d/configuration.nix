{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../common/nvidia/configuration.nix
    ../../common/streampc/configuration.nix
  ];
}
