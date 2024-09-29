# common configuration.nix for desktop machines

{ pkgs, user, ... }:
let
  consts = import ../../common/consts.nix;
in
{

  imports = [
    ../limits/configuration.nix
    ../hosts/configuration.nix
    ../mitigations/configuration.nix
    ../locale/configuration.nix
    ../nix/configuration.nix
    ../gnome/configuration.nix
    ../dnscrypt/configuration.nix
    ../ssh/configuration.nix
    ../autologin/configuration.nix
  ];

  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "adbusers" ];
  };

  programs.adb.enable = true;

  services.libinput = {
    enable = true;
    mouse.accelProfile = "flat";
    touchpad.accelProfile = "flat";
  };

  networking = {
    domain = "localhost";
    usePredictableInterfaceNames = false;
    networkmanager.enable = true;
  };

  programs.nm-applet.enable = true;
  programs.nix-ld.enable = true; # to run non-nixos bins

  hardware.bluetooth = {
    enable = true;

    # TODO: is this still doing anything?
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  services.blueman.enable = true;

  services.gvfs.enable = true; # for nautilus
  services.udisks2.enable = true; # to mount removable devices more easily

  # don't wanna get stuck in emergency mode over benign errors
  systemd.enableEmergencyMode = false;

  systemd.user.services.startup-apps =
    let
      apps = with pkgs; [
        chatterino2
        firefox
        telegram-desktop
        armcord
        gimp
      ];
    in
    {
      enable = true;
      description = "Various custom start-up apps";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        RemainAfterExit = "yes";
        Type = "oneshot";
      };

      script = builtins.concatStringsSep "\n" (map (x: "${x.meta.mainProgram} &") apps);
    };

  # NOTE: private config files. comment out or provide your own

  # by default, agenix does not look in your home dir for keys
  # TODO: do not hardcode this home path, get it from home-manager somehow or something
  age.identityPaths = [
    "/home/${user}/.ssh/id_rsa"
  ];

  # agenix secrets are owned by root and symlinked from /run/agenix.d .
  # so to have user-owned secrets I have to disable symlinking and make sure the ownership is correct
  age.secrets =
    let

      mkUserSecret = { file, path }: {
        inherit file path;
        owner = "${user}";
        group = "users";
        symlink = false;
      };

      secretPath = path: "/var/lib/${user}-secrets/${path}";

    in
    {

      gh2md-token = mkUserSecret {
        file = ../../secrets/gh2md/token.age;
        path = "/home/${user}/.config/gh2md/token";
      };

      gist-token = mkUserSecret {
        file = ../../secrets/gist/token.age;
        path = "/home/${user}/.gist";
      };

      chatterino-settings = mkUserSecret {
        file = ../../secrets/chatterino/settings.json.age;
        path = "/home/${user}/.local/share/chatterino/Settings/settings.json";
      };

      protonvpn-creds = mkUserSecret {
        file = ../../secrets/protonvpn/creds.txt.age;
        path = "/home/${user}/.local/share/protonvpn/creds.txt";
      };

      protonvpn-conf = mkUserSecret {
        file = ../../secrets/protonvpn/config.ovpn.age;
        path = "/home/${user}/.local/share/protonvpn/config.ovpn";
      };

    };

}
