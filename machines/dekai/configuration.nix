{ config, pkgs, lib, user, configName, ... }:


let
  consts = import ../../common/consts.nix;
  inherit (consts.ssh) authorizedKeys;
  machine = consts.machines.${configName};
  archiveboxPort = 7777;

in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../common/nix/configuration.nix
      ../../common/locale/configuration.nix
      ../../common/dnscrypt/configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-901be401-55e0-4047-a286-bb53898060de".device = "/dev/disk/by-uuid/901be401-55e0-4047-a286-bb53898060de";

  networking = {
    hostName = "dekai";
    hostId = "09952a93";
    usePredictableInterfaceNames = false;
    useDHCP = false;

    interfaces."${machine.iface}".ipv4.addresses = [{
      address = machine.ip;
      prefixLength = 24;
    }];

    defaultGateway = {
      interface = machine.iface;
      address = consts.ips.gateway;
    };

    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
        22 # ssh
        80 # http
        443 # https
        5357 # wsdd, for samba win10 discovery
        archiveboxPort
      ];
      allowedUDPPorts = [
        3702 # wsdd, for samba win10 discovery
      ];
    };
  };


  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  environment.variables = { EDITOR = "vim"; };

  environment.systemPackages = with pkgs; [
    ((vim_configurable.override { }).customize {
      name = "vim";
      vimrcConfig.customRC = (builtins.readFile ../../common/vim/init.vim);
    })
  ];

  users.users."${user}" = {
    isNormalUser = true;
    description = "${user}";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = (with pkgs; [
      btop
      tmux
      internetarchive
      vim
    ]);
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

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
    shares =
      let
        sharecfg = {
          browseable = "yes";
          "guest ok" = "no";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "${user}";
          "force group" = "users";
        };
      in
      {
        memevault = sharecfg // {
          path = "/memevault";
        };

        public = sharecfg // {
          path = "/mnt/Shares/Public";
          "guest ok" = "yes";
        };
      };
  };

  services.openssh.enable = true;

  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "yes";
    KbdInteractiveAuthentication = false;
  };

  programs.ssh.knownHosts = consts.ssh.knownHosts;

  systemd.services.archivebox = {
    enable = true;
    description = "Archivebox server";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      User = user;
      Group = "users";
      WorkingDirectory = "/memevault/memes/archivebox";
      Environment = [
        "NODE_BINARY=${pkgs.nodejs}/bin/node"
        "SINGLEFILE_BINARY=${pkgs.single-file-cli}/bin/single-file"
      ];
      ExecStart = ''
        ${pkgs.archivebox}/bin/archivebox server ${machine.ip}:${toString archiveboxPort}
      '';
    };
  };

  services.nextcloud = {
    enable = true;
    hostName = machine.ip;
    config.adminpassFile = config.age.secrets.nextcloud-pass.path;
    package = pkgs.nextcloud29;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) onlyoffice;
    };
    extraAppsEnable = true;
  };

  # by default, agenix does not look in your home dir for keys
  age.identityPaths = [
    "/root/.ssh/id_ed25519"
  ];

  # agenix secrets are owned by root and symlinked from /run/agenix.d .
  # so to have user-owned secrets I have to disable symlinking and make sure the ownership is correct
  age.secrets =
    let

      secretPath = path: "/var/lib/secrets/${path}";

      mkSecret = { file, path }: {
        inherit file;
        path = secretPath path;
        symlink = false;
      };

    in
    {

      nextcloud-pass = mkSecret {
        file = ../../secrets/nextcloud/password.age;
        path = "nextcloud/password.txt";
      } // {
        owner = "nextcloud";
      };

    };

  system.stateVersion = "23.11";

}
