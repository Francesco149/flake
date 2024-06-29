{ config, pkgs, lib, user, ... }:

let

  consts = import ../../common/consts.nix;
  inherit (consts.ssh) authorizedKeys;

in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # Enable swap on luks
  boot.initrd.luks.devices."luks-ac66aa94-2a1a-47f5-b6a1-d4cf2f14a2b4".device = "/dev/disk/by-uuid/ac66aa94-2a1a-47f5-b6a1-d4cf2f14a2b4";
  boot.initrd.luks.devices."luks-ac66aa94-2a1a-47f5-b6a1-d4cf2f14a2b4".keyFile = "/crypto_keyfile.bin";

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";

  # automatically garbage collect nix store to save disk space
  nix.gc.automatic = true;
  nix.gc.dates = "03:15";

  # don't wanna get stuck in emergency mode over benign errors
  systemd.enableEmergencyMode = false;

  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

  networking = {
    hostName = "meido";
    usePredictableInterfaceNames = false;
    nameservers = [ "127.0.0.1" "::1" ];
    defaultGateway = consts.ips.gateway;
    resolvconf.enable = false;
    dhcpcd.enable = false;
  };

  networking.interfaces.eth0.ipv4.addresses = [{
    address = consts.machines.meido.ip;
    prefixLength = 24;
  }];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "francesco149@gmail.com";

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "yes";
    KbdInteractiveAuthentication = false;
  };

  users.users.git = {
    isNormalUser = true;
    description = "git user";
    createHome = false;
    home = "/home/git";
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  programs.bash.shellAliases = {
    git-su = "sudo su -s '${pkgs.bash}/bin/bash' - git";
  };

  environment.interactiveShellInit = ''
    git-init() {
      sudo -u git sh -c "mkdir \$HOME/$1.git && git -C \$HOME/$1.git init --bare"
    }
  '';

  services.samba-wsdd.enable = true; # make shares visible for windows 10 clients

  services.samba = {
    enable = true;
    openFirewall = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = smbnix
      netbios name = smbnix
      security = user
      #use sendfile = yes
      #max protocol = smb2
      # note: localhost is the ipv6 localhost ::1
      hosts allow = ${consts.ips.pre} 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
      public = {
        path = "/mnt/Shares/Public";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "${user}";
        "force group" = "users";
      };
      private = {
        path = "/mnt/Shares/Private";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "${user}";
        "force group" = "users";
      };
    };
  };

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      22 # ssh
      5357 # wsdd, for samba win10 discovery
    ];
    allowedUDPPorts = [
      3702 # wsdd, for samba win10 discovery
    ];
  };

  system.stateVersion = "22.11";

}
