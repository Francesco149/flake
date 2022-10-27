{ pkgs, user, nixos-wsl, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    nixos-wsl.nixosModules.wsl

    ../configuration.nix
  ];

  nix = {
    package = pkgs.nixVersions.nixos-22.05;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    settings.trusted-users = [ "root" user ];
  };

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
