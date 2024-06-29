{ pkgs, user, nixos-wsl, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    nixos-wsl.nixosModules.wsl
    ../../common/locale/configuration.nix
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    settings.trusted-users = [ "root" user ];
  };

  system.stateVersion = "22.05";

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = user;
    startMenuLaunchers = true;

    # Enable native Docker support
    # docker-native.enable = true;

    # Enable integration with Docker Desktop (needs to be installed)
    # docker.enable = true;
  };

}
