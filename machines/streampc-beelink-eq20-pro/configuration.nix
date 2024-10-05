{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../common/i915/configuration.nix
    ../../common/streampc/configuration.nix
  ];
}
