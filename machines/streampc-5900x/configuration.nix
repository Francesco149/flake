{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../common/amdgpu/configuration.nix
    ../../common/streampc/configuration.nix
  ];
}
