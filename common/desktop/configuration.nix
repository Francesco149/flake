# common configuration.nix for desktop machines

{ pkgs, user, meidoLocalIp, ... }:

let

  authorizedKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpNgs8JFiW2okM8bWoQXkXD6y3x1LONA3hNQbUmvJhMK8BP7Ajkd5avC0dhyOnHee1WCoiQfCfqN/2SVgHMDmRv2QNluciZ4scFr1IwXRxrUqRPpDid6bBIc/e7PYcFBfA2r1nfOdZTePiQcQAcb0yhblqtsg9aOgl+JwqK4GvoQgwriB3Hp6PrezRYBcQjjLbcrU8U1vqKCljhL/cYy5qj5ybJ4hRYcsuZoiQxjtomlrsmibVcTJZVnwPL3DVhCcNrPYABstVgLZfLSttCQCdB2VvGJOx5r6gaB8bkgHsqgERyZza4hBYsMPLSuzxrxgEH+AZzTBGIZiWD0WgY+81 loli@void"
  ];

in {

  imports = [
    ../locale/configuration.nix
  ]

  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  services.getty.autologinUser = user;

  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;
  services.openssh.enable = true;

  # workaround for race condition in autologin
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  services.xserver.libinput = {
    enable = true;
    mouse.accelProfile = "flat";
    touchpad.accelProfile = "flat";
  };

  # automatically garbage collect nix store to save disk space
  nix.gc = {
    automatic = true;
    dates = "13:00";
    options = "--delete-older-than 7d";
  };

  nix = {
    package = pkgs.nixVersions.unstable;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    settings.trusted-users = [ "root" user ];
  };

  networking = {
    domain = "localhost";
    usePredictableInterfaceNames = false;
    nameservers = [ meidoLocalIp ];
    resolvconf.enable = false;
  };

  sound.enable = true;
  hardware.pulseaudio.enable = true;

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

  # TODO: check if this is actually required for bluetooth
  hardware.pulseaudio.package = pkgs.pulseaudioFull;

  services.gvfs.enable = true; # for nautilus
  services.udisks2.enable = true; # to mount removable devices more easily

  # don't wanna get stuck in emergency mode over benign errors
  systemd.enableEmergencyMode = false;

  # only use on machines where security is not important and performance is critical.
  # this makes the cpu vulnerable to many exploits.

  boot.kernelParams = [
    "usbhid.kbpoll=1"
    "usbhid.mousepoll=1"
    "usbhid.jspoll=1"
    "noibrs"
    "noibpb"
    "nopti"
    "nospectre_v2"
    "nospectre_v1"
    "l1tf=off"
    "nospec_store_bypass_disable"
    "no_stf_barrier"
    "mds=off"
    "mitigations=off"
  ];

  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "";
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = false;
    displayManager.autoLogin.enable = true;
    displayManager.autoLogin.user = "${user}";
  };

  services.xserver.desktopManager.session = [
    {
      name = "home-manager";
      start = ''
        ${pkgs.runtimeShell} $HOME/.hm-xsession &
        waitPID=$!
      '';
    }
  ];

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      22 # ssh
    ];
  };

  # NOTE: private config files. comment out or provide your own

  # by default, agenix does not look in your home dir for keys
  # TODO: do not hardcode this home path, get it from home-manager somehow or something
  age.identityPaths = [
    "/home/${user}/.ssh/id_rsa"
  ];

  # agenix secrets are owned by root and symlinked from /run/agenix.d .
  # so to have user-owned secrets I have to disable symlinking and make sure the ownership is correct
  age.secrets = let

    mkUserSecret = { file, path }: {
      inherit file path;
      owner = "${user}";
      group = "users";
      symlink = false;
    };

    secretPath = path: "/var/lib/${user}-secrets/${path}";

  in {

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

  };

}
