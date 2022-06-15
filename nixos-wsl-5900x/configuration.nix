{ pkgs, user, nixos-wsl, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    nixos-wsl.nixosModules.wsl

    ./hardware-configuration.nix
    ../configuration.nix
  ];

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "loli";
    startMenuLaunchers = true;

    # Enable integration with Docker Desktop (needs to be installed)
    # docker.enable = true;
  };

  networking.dhcpcd.enable = true;

}
