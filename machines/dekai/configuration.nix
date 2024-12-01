{ config, pkgs, lib, user, configName, ... }:


let
  consts = import ../../common/consts.nix;
  inherit (consts.ssh) authorizedKeys;
  machine = consts.machines.${configName};
  archiveboxPort = 7777;
  collaboraPort = 9980;
  collaboraSPort = toString collaboraPort;

in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../common/boot/configuration.nix
      ../../common/hosts/configuration.nix
      ../../common/nix/configuration.nix
      ../../common/locale/configuration.nix
      ../../common/dnscrypt/configuration.nix
    ];

  boot.initrd.luks.devices."luks-901be401-55e0-4047-a286-bb53898060de".device = "/dev/disk/by-uuid/901be401-55e0-4047-a286-bb53898060de";

  services.nginx.defaultListenAddresses = [ machine.ip ];

  networking = {
    hostName = "dekai";
    hostId = "09952a93";
    usePredictableInterfaceNames = false;
    useDHCP = false;

    wireless.enable = true;
    wireless.userControlled.enable = true;

    interfaces."${machine.iface}".ipv4.addresses = [{
      address = machine.ip;
      prefixLength = 24;
    }
    {
      address = consts.lancacheIp;
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
        8123 # home-assistant
      ];
      allowedUDPPorts = [
        3702 # wsdd, for samba win10 discovery
        137 138 # nmbd
      ];
    };
  };

  virtualisation.docker.enable = true;
  services.dbus.implementation = "broker";
  hardware.bluetooth.enable = true;
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
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = (with pkgs; [
      btop
      tmux
      internetarchive
      vim
    ]);
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

  # shut down when ups battery level is too low.
  # also allows me to check the load by doing `apcaccess -pLOADPCT`
  services.apcupsd = {
    enable = true;
    configText = ''
      UPSTYPE usb
      NISIP 127.0.0.1
      BATTERYLEVEL 10
      MINUTES 5
    '';
  };

  services.samba-wsdd.enable = true; # make shares visible for windows 10 clients

  services.samba = {
    enable = true;
    enableNmbd = true;
    enableWinbindd = true;
    openFirewall = true;
    settings =
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

        photos = sharecfg // {
          path = "/mnt/Shares/Photos";
        };

        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "DEKAI";
          "netbios name" = "DEKAI";
          "security" = "user";
          #use sendfile = yes
          #max protocol = smb2
          # note: localhost is the ipv6 localhost ::1
          "hosts allow" = "${consts.ips.pre} 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
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
    enable = false; # TODO: TEMPORARILY BROKEN because of django failing to build
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
    hostName = machine.domains.cloud;
    config.adminpassFile = config.age.secrets.nextcloud-pass.path;
    package = pkgs.nextcloud30;
    https = true;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) richdocuments;
    };
    extraAppsEnable = true;
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    sslCertificate = config.age.secrets.nginx-selfsigned-crt.path;
    sslCertificateKey = config.age.secrets.nginx-selfsigned-key.path;
  };

  # https://discourse.nixos.org/t/enabling-nextcloud-office/31349/3
  virtualisation.oci-containers.containers.collabora = {
    image = "docker.io/collabora/code:latest";
    ports = [ "${collaboraSPort}:${collaboraSPort}/tcp" ];
    environment = {
      dictionaries = "en_US";
      extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
      server_name = machine.domains.office;
      aliasgroup1 = "https://${machine.domains.cloud}:443";
    };
    extraOptions = [
      "--pull=newer"
    ];
  };

  services.nginx.virtualHosts.${config.virtualisation.oci-containers.containers.collabora.environment.server_name} = {
    forceSSL = true;
    sslCertificate = config.age.secrets.nginx-selfsigned-crt.path;
    sslCertificateKey = config.age.secrets.nginx-selfsigned-key.path;

    extraConfig = ''
       # static files
       location ^~ /browser {
         proxy_pass http://127.0.0.1:${collaboraSPort};
         proxy_set_header Host $host;
       }

       # WOPI discovery URL
       location ^~ /hosting/discovery {
         proxy_pass http://127.0.0.1:${collaboraSPort};
         proxy_set_header Host $host;
       }

       # Capabilities
       location ^~ /hosting/capabilities {
         proxy_pass http://127.0.0.1:${collaboraSPort};
         proxy_set_header Host $host;
      }

      # main websocket
      location ~ ^/cool/(.*)/ws$ {
        proxy_pass http://127.0.0.1:${collaboraSPort};
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 36000s;
      }

      # download, presentation and image upload
      location ~ ^/(c|l)ool {
        proxy_pass http://127.0.0.1:${collaboraSPort};
        proxy_set_header Host $host;
      }

      # Admin Console websocket
      location ^~ /cool/adminws {
        proxy_pass http://127.0.0.1:${collaboraSPort};
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 36000s;
      }
    '';
  };

  services.lancache = {
    enable = true;
    cacheLocation = "/mnt/storage/lancache";
    logPrefix = "/var/log/nginx/lancache";
    listenAddress = "192.168.1.5";
    upstreamDns = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    cacheDiskSize = "1000g";
    cacheIndexSize = "250m";
    cacheMaxAge = "3560d";
    minFreeDisk = "10g";
    sliceSize = "1m";
    logFormat = "cachelog";

    domainsPackage = pkgs.fetchFromGitHub {
      owner = "uklans";
      repo = "cache-domains";
      rev = "1f5897f4dacf3dab5f4d6fca2fe497d3327eaea9";
      sha256 = "sha256-xrHuYIrGSzsPtqErREMZ8geawvtYcW6h2GyeGMw1I88=";
    };

    workerProcesses = "auto";
  };

  services.home-assistant = {
    enable = true;
    extraComponents = [
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      "default_config"

      # Components required to complete the onboarding
      "esphome"
      "met"
      "radio_browser"
    ];
    customComponents = with pkgs.home-assistant-custom-components; [
      tuya_local
    ];
    config = {

    };
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

      nextcloud-pass = mkSecret
        {
          file = ../../secrets/nextcloud/password.age;
          path = "nextcloud/password.txt";
        } // {
        owner = "nextcloud";
      };

      nginx-selfsigned-crt = mkSecret
        {
          file = ../../secrets/nginx/nginx-selfsigned.crt.age;
          path = "nginx/selfsigned.crt";
        } // {
        owner = "nginx";
      };

      nginx-selfsigned-key = mkSecret
        {
          file = ../../secrets/nginx/nginx-selfsigned.key.age;
          path = "nginx/selfsigned.key";
        } // {
        owner = "nginx";
      };

    };

  system.stateVersion = "23.11";

}
