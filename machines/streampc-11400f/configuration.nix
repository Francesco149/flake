{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../common/nvidia/configuration.nix
    ../../common/streampc/configuration.nix
  ];

  system.stateVersion = "23.05";
}
