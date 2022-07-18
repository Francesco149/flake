{ pkgs, user, nixos-wsl, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    nixos-wsl.nixosModules.wsl

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

  programs.dconf.enable = true; # for home-manager

}
