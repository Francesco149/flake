{ config, pkgs, lib, user, configName, ... }:


let
  consts = import ../../common/consts.nix;
  inherit (consts.ssh) authorizedKeys;
  machine = consts.machines.${configName};
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
      ../../common/gnome/configuration.nix
    ];

  boot.initrd.luks.devices."luks-901be401-55e0-4047-a286-bb53898060de".device = "/dev/disk/by-uuid/901be401-55e0-4047-a286-bb53898060de";

  services.nginx.package = pkgs.nginxMainline.override { withSlice = true; };
  services.nginx.defaultListenAddresses = [ machine.ip ];

  networking = {
    hostName = "dekai";
    hostId = "09952a93";
    usePredictableInterfaceNames = false;
    useDHCP = false;

    # NOTE: these interface settings are not actually applied with gnome because
    #       network manager takes over. so I have to manually config these for now.
    #       TODO: declarative network manager config
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
        8123 # home-assistant
      ];
      allowedUDPPorts = [
        3702 # wsdd, for samba win10 discovery
        137 138 # nmbd
        53 # lancache
      ];
    };
  };

  virtualisation.docker.enable = true;
  services.dbus.implementation = "broker";
  hardware.bluetooth.enable = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.kernelParams = [ "zfs.zfs_arc_max=107400000000" ];
  services.zfs.autoScrub = {
    enable = true;
    interval = "quarterly";
  };
  services.zfs.trim.enable = true;

  environment.variables = { EDITOR = "vim"; };

  environment.systemPackages = with pkgs; [
    ((vim-full.override { }).customize {
      name = "vim";
      vimrcConfig.customRC = (builtins.readFile ../../common/vim/init.vim);
    })
  ];

  users.users."${user}" = {
    isNormalUser = true;
    description = "${user}";
    extraGroups = [ "networkmanager" "wheel" "docker" "audio" ];
    packages = (with pkgs; [
      btop
      tmux
      internetarchive
      vim
      chatterino7
    ]);
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

  # loopback device (virtual mic)
  services.pipewire.extraConfig.pipewire = {

    "10-loopback"."context.modules" =
      let
        sinkName = x: (builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower x)) + "_sink";
        loopbackD = x: delaySec: {
          name = "libpipewire-module-loopback";
          args = {
            "audio.position" = [ "FL" "FR" ];
            "target.delay.sec" = delaySec;
            "capture.props" = {
              "media.class" = "Audio/Sink";
              "node.name" = sinkName x;
              "node.description" = "${x} Sink (In)";
            };

            # the loopback device already has a built in output.
            # this is more useful if you need to hardwire it to a device with node.target

            "playback.props" = {
              "media.class" = "Audio/Source";
              "node.name" = (sinkName x) + "_out";
              "node.description" = "${x} Sink (Out)";
              "target.object" = "null-sink";
              "node.dont-reconnect" = true;
              "stream.dont-remix" = true;
              "node.passive" = true;
            };
          };
        };
        loopback = x: loopbackD x 0.0;
      in
      [
        (loopback "Loopback")
      ];

    # this makes the jack monitors properly restore in carla
    "01-jack-monitor"."jack.properties"."jack.merge-monitor" = true;

    # null audio sink for when I want to default audio output to nothing
    "20-null"."context.objects" = [
      {
        factory = "adapter";
        args = {
          "factory.name" = "support.null-audio-sink";
          "node.name" = "null-sink";
          "node.description" = "sound black hole";
          "media.class" = "Audio/Sink";
          "object.linger" = 1;
          "audio.position" = [ "FL" "FR" ];
        };
      }
    ];
  };

  systemd.user.services.startup-apps = {
    enable = true;
    description = "Various custom start-up apps";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      RemainAfterExit = "yes";
      Type = "oneshot";
    };

    script = ''
      ${pkgs.carla}/bin/carla-jack-multi &
      ${pkgs.chatterino7}/bin/chatterino &
    '';
  };

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
        private = sharecfg // {
          path = "/gigavault/private";
        };

        uwu = sharecfg // {
          path = "/gigavault/uwu";
        };

        footage = sharecfg // {
          path = "/gigavault/footage";
          "guest ok" = "yes";
        };

        public = sharecfg // {
          path = "/gigavault/public";
          "guest ok" = "yes";
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

  services.nextcloud = {
    enable = true;
    hostName = machine.domains.cloud;
    config.adminpassFile = config.age.secrets.nextcloud-pass.path;
    package = pkgs.nextcloud31;
    https = true;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) richdocuments;
    };
    extraAppsEnable = true;

    config.dbtype = "sqlite"; # TODO: migrate to pg
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
    listenAddress = consts.lancacheIp;
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

  services.bind = {
    enable = true;

    extraOptions = ''
      recursion yes;

      allow-recursion {
        localnets;
        localhost;
        192.168.1.0/24;
      };
    '';
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
