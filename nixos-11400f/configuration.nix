{ pkgs, user, lib, config, ... }:

let
  pgdb = name: "postgres://${name}@localhost/${name}?sslmode=disable";

  appservice-pgdb = name: {
    engine = "postgres";
    connString = pgdb name;
    filename = "";
  };

  dendriteLocalPort = 8007;
  dendriteLocalUrl = "http://localhost:${toString dendriteLocalPort}";

  synapseLocalPort = 8008;
  synapseLocalUrl = "http://localhost:${toString synapseLocalPort}";

  # can't extract this from dendrite's module it seems. also referencing the systemd service causes inf recursion
  dendriteDataDir = "/var/lib/dendrite";

  # generates a service that runs as root and installs files into the service's data directory
  # with correct ownership for a DynamicUser service. they will be read-only for the user.
  # this is meant for secrets.

  # usage:
  # imports = [
  #   (serviceFiles "myService" [ "/path/to/file.ext" ])
  #   #... your other imports
  # ];
  # services.myService = {
  #   # ... yourother settings
  # };

  serviceFilesWithDir = dataDir: serviceName: files: {
    systemd.services."${serviceName}".after = [ "${serviceName}-serviceFiles.service" ];
    systemd.services."${serviceName}-serviceFiles" = {
      enable = true;
      restartIfChanged = true;
      description = "Install files to ${serviceName}'s dataDir";
      before = [ "${serviceName}.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = (pkgs.writeShellScript "${serviceName}-serviceFiles-ExecStart" ''
          install \
            --verbose \
            --mode 400 \
            --owner $(stat -c %u "${dataDir}") \
            --group $(stat -c %g "${dataDir}") \
            ${builtins.concatStringsSep " " files} \
            "${dataDir}"
        '');
        RemainAfterExit = true;
      };
    };
  };

  # simplified version for services that provide dataDir at config.services.${serviceName}.dataDir
  serviceFiles = serviceName: files:
    serviceFilesWithDir config.services.${serviceName}.dataDir serviceName files;

  # generate matrix synapse worker config to be written to a synapse yaml file. based on
  # https://github.com/sumnerevans/nixos-configuration/blob/master/modules/services/matrix/synapse/default.nix

  # port is the metrics port for prometheus.
  # config is extra config to merge into the result

  synapseWorkerConfig = port: config: let
    newConfig = {
      # The replication listener on the main synapse process.
      worker_replication_host = "127.0.0.1";
      worker_replication_http_port = 9093;

      # Default to generic worker.
      worker_app = "synapse.app.generic_worker";
    } // config;
    newWorkerListeners = (config.worker_listeners or [ ]) ++ [
      {
        type = "metrics";
        bind_address = "";
        port = port;
      }
    ];
  in
    newConfig // { worker_listeners = newWorkerListeners; };

  # generates the systemd service a matrix synapse worker. see synapseWorkerConfig
  synapseWorker = name: port: workerConfig: let
    yamlFormat = pkgs.formats.yaml { };
    configFileObj = (synapseWorkerConfig port { worker_name = name; } // workerConfig);
    configFile = yamlFormat.generate "${name}.yaml" configFileObj;
    dataDir = config.services.matrix-synapse.dataDir;
  in {
    # this is so I can't typo/don't have to repeat the worker name, ports and other stuff elsewhere
    services.matrix-synapse.customWorkers.${name} = configFileObj;

    systemd.services."matrix-synapse-${name}" = {
      enable = true;
      restartIfChanged = true;
      description = "Synapse Matrix worker: ${name}";
      after = [ "matrix-synapse.service" ];
      partOf = [ "matrix-synapse.target" ];
      wantedBy = [ "matrix-synapse.target" ];
      serviceConfig = {
        Type = "notify";
        User = "matrix-synapse";
        Group = "matrix-synapse";
        WorkingDirectory = dataDir;
        ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
        UMask = "0077";
        ExecStart = ''
          ${pkgs.matrix-synapse}/bin/synapse_worker \
            ${ lib.concatMapStringsSep "\n  " (x: "--config-path ${x} \\")
              ([config.services.matrix-synapse.configFile configFile]
              ++ config.services.matrix-synapse.extraConfigFiles) }
            --keys-directory ${dataDir}
        '';
      };
    };
  };

in
{
  imports = [
    ./hardware-configuration.nix
    ../configuration.nix

    (serviceFiles "matrix-synapse" [
      "${config.age.secrets.synapse-homeserver-signing-key.path}"
      "${config.age.secrets.synapse-secrets.path}"
      "${config.age.secrets.matrix-appservice-discord-registration.path}"
    ])

    (serviceFilesWithDir dendriteDataDir "dendrite" [
      "${config.age.secrets.dendrite-private-key.path}"
    ])

    ({ options.services.matrix-synapse.customWorkers = lib.mkOption { default = {}; }; })

    # NOTE: tls and compression are off by default for workers
    (synapseWorker "federation-sender1" 9101 { worker_app = "synapse.app.federation_sender"; })

    (synapseWorker "federation-reader1" 9102 {
      worker_listeners = [
        {
          type = "http";
          port = 8009;
          bind_address = "0.0.0.0";
          x_forwarded = true;
          resources = [
            { names = [ "federation" ]; compress = false; }
          ];
        }
      ];
    })

    (synapseWorker "event-persister1" 9103 {
      worker_listeners = [
        {
          type = "http";
          port = 9091;
          bind_address = "127.0.0.1";
          resources = [{ names = [ "replication" ]; }];
        }
      ];
    })

    (synapseWorker "client-worker1" 9104 {
       worker_listeners = [
        {
          type = "http";
          port = 8010;
          bind_address = "0.0.0.0";
          resources = [{ names = [ "client" ]; }];
        }
      ];
    })

    (synapseWorker "media-repo1" 9104 {
       worker_app = "synapse.app.media_repository";
       worker_listeners = [
        {
          type = "http";
          port = 8011;
          bind_address = "0.0.0.0";
          resources = [{ names = [ "media" ]; }];
        }
      ];
    })

  ];

  networking.hostName = "nixos";
  networking.hostId = "8556b001";
  networking.interfaces.br0.ipv4.addresses = [{
    address = "192.168.1.9";
    prefixLength = 24;
  }];
  networking.dhcpcd.enable = false;

  boot.supportedFilesystems =  [ "zfs" ];
  boot.zfs.devNodes = "/dev/";
  boot.kernelParams = [
    "amd_iommu=on"
    "intel_iommu=on"
    "iommu=pt"
    "rd.driver.pre=vfio-pci"
    "pcie_acs_override=downstream,multifunction"
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
    "amdgpu.ppfeaturemask=0xffffffff"
    "zfs.zfs_arc_max=2147483648"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.zfs.trim.enable = true;
  services.nfs.server.enable = true;

  services.zfs.autoScrub = {
    enable = true;
    pools = [ "rpool" ];
  };

  services.zfs.autoSnapshot = {
    enable = true;
    frequent = 96; # keep the latest x 15-minute snapshots (instead of four)
    monthly = 24;  # keep x monthly snapshot (instead of twelve)
  };

  # according to the wiki, zfs has its own scheduler and this supposedly prevent freezes
  # I haven't had any issues personally
  services.udev.extraRules = ''
  ACTION=="add|change", KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"
  '';

  # bridge + tap setup for qemu
  networking.bridges.br0 = {
    rstp = false;
    interfaces = [ "eth0" ];
  };

  networking.interfaces.br0.virtual = true;

  environment.etc."qemu/bridge.conf".text = "allow br0";

  networking.interfaces.tap0 = {
    virtualOwner = "${user}";
    virtual = true;
    virtualType = "tap";
    useDHCP = true;
  };

  networking.defaultGateway = {
    interface = "br0";
    address = "192.168.1.1";
  };

  services.xserver = {
    enable = true;
    layout = "us";
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

  # workaround for race condition in autologin
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  services.xserver.libinput = {
    enable = true;
    mouse.accelProfile = "flat";
    touchpad.accelProfile = "flat";
  };

  services.xserver.xkbOptions = "caps:escape";

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      22 # ssh
      80 # http
      443 # https
      8448 # matrix
      8420 # dendrite
    ];
  };

  # postgresql: just used by matrix for now

  services.postgresql = let
    db = name: {
      inherit name;
      ensurePermissions = {
        "DATABASE \"${name}\"" = "ALL PRIVILEGES";
      };
    };

    # using collation other than C can cause subtle corruption in your indices if libc/icu changes stuff.
    # this script recreates template1, the default database template, to have collation C
    # https://www.citusdata.com/blog/2020/12/12/dont-let-collation-versions-corrupt-your-postgresql-indexes/
    initialScript = ''
      ALTER database template1 is_template=false;
      DROP database template1;

      CREATE DATABASE template1
      WITH OWNER = postgres
        ENCODING = 'UTF8'
        TABLESPACE = pg_default
        LC_COLLATE = 'C'
        LC_CTYPE = 'C'
        CONNECTION LIMIT = -1
        TEMPLATE template0;

      ALTER database template1 is_template=true;
    '';

    svc = name: lib.optional config.services.${name}.enable name;
    svcs = (svc "dendrite")
      ++ (svc "matrix-synapse")
      ++ (svc "matrix-appservice-discord");
  in {
    enable = true;
    # package = pkgs.postgresql_14;
    enableTCPIP = true;

    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';

    ensureDatabases = svcs;
    ensureUsers = map (x: (db x)) svcs;
  };

  # redis: just used by matrix now. used for inter-process communication
  services.redis.enable = true;

  # synapse: matrix server
  # nginx is expected to handle https and proxy to the local http

  services.matrix-synapse.enable = true;
  services.matrix-synapse.settings = let
    db = pgdb "matrix-synapse";
    dataDir = config.services.matrix-synapse.dataDir;
    wrk = config.services.matrix-synapse.customWorkers;
  in {
    server_name = "animegirls.win";
    max_upload_size = "1000M";

    redis.enabled = true;
    send_federation = false;
    enable_media_repo = false;

    federation_sender_instances = [
      wrk.federation-sender1.worker_name
    ];

    instance_map.${wrk.event-persister1.worker_name} = {
      host = "localhost";
      port = (builtins.elemAt wrk.event-persister1.worker_listeners 0).port;
    };

    stream_writers = {
      events = wrk.event-persister1.worker_name;
    };

    experimental_features = {
      spaces_enabled = true;

      #msc2716_enabled = true; # history backfilling

      # NOTE: do not enable faster_joins, apparently it has caused corruption
      # https://github.com/matrix-org/synapse/issues/12878
      #faster_joins = true; # use msc3706 if using workers

      #msc3030_enabled = true; # get events at given timestamp
    };

    # these have good defaults already but I just wanna ensure they stick even if the default changes
    enable_registration = false;
    registration_shared_secret = null;
    macaroon_secret_key = null;
    enable_metrics = false;
    report_stats = false;
    presence.enabled = false;

    extraConfigFiles = [
      "${dataDir}/secrets.yaml"
    ];

    app_service_config_files = [
      #"${dataDir}/matrix-appservice-discord-registration.yaml"
    ];

    database = {
      name = "psycopg2";
      args.host = "localhost";
    };

    listeners = [
      {
        port = synapseLocalPort;
        bind_addresses = [ "127.0.0.1" ];
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [
          {
            names = [ "client" ];
            compress = true;
          }
          {
            names = [ "federation" ];
            compress = false;
          }
        ];
      }
      {
        port = 9093;
        bind_addresses = [ "127.0.0.1" ];
        type = "http";
        tls = false;
        resources = [
          {
            names = [ "replication" ];
            compress = false;
          }
        ];
      }
    ];

    trusted_key_servers = [
      {
        server_name = "matrix.org";
        verify_keys = {
          "ed25519:auto" = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw";
          "ed25519:a_RXGa" = "l8Hft5qXKn1vfHrg3p4+W8gELQVo8N13JkluMfmn2sQ";
        };
      }
      {
        server_name = "midov.pl";
        verify_keys."ed25519:a_HXVM" = "4FOGNjNLe3LNGHgDGIMVm3Yx9IQZZnn1LDqv5O1xIns";
      }
      {
        server_name = "tchncs.de";
        verify_keys."ed25519:a_rOPL" = "HZxh/ZZktCgLcsJgKw2tHS9lPcOo1kNBoEdeVtmkpeg";
      }
    ];

  };

  # convert the synapse service into a unit so I can add workers and other dependent services to it
  systemd.targets.matrix-synapse = {
    description = "Synapse processes";
    after = [ "network.target" "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
  };
  systemd.services.matrix-synapse.partOf = [ "matrix-synapse.target" ];
  systemd.services.matrix-synapse.wantedBy = [ "matrix-synapse.target" ];

  # bridges and other matrix appservices

  services.matrix-appservice-discord = {
    enable = false;
    environmentFile = config.age.secrets.matrix-appservice-discord-environment.path;

    settings.bridge = {
      domain = "animegirls.win";
      homeserverUrl = synapseLocalUrl;
      enableSelfServiceBridging = true;
    };

    settings.database = appservice-pgdb "matrix-appservice-discord";
  };

  # dendrite: experimental matrix server

  # this is not my main homeserver because it currently has some issue with encrypted rooms (messages not
  # being visible for others or just sending very slow), as well as issues making spaces federate properly
  # (space summary doesn't show properly from other HS's)

  # bridges I tested that worked with dendrite:
  # - matrix-appservice-discord

  # we don't need to run it in https mode because nginx does the job of handling https requests,
  # providing the cert and redirecting the connection to the local http port

  services.dendrite = {
    enable = true;
    httpPort = dendriteLocalPort;
  };

  services.dendrite.settings = let
    db = pgdb "dendrite";
    dataDir = dendriteDataDir;
  in {
    global.server_name = "animegirls.cc";
    global.private_key = "${dataDir}/matrix_key.pem";

    global.trusted_third_party_id_servers = [
      "midov.pl"
      "tchncs.de"
      "matrix.org"
    ];

    federation_api.key_perspectives = [
      {
        server_name = "matrix.org";
        keys = [
          {
            key_id = "ed25519:auto";
            public_key = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw";
          }
          {
            key_id = "ed25519:a_RXGa";
            public_key = "l8Hft5qXKn1vfHrg3p4+W8gELQVo8N13JkluMfmn2sQ";
          }
        ];
      }
      {
        server_name = "midov.pl";
        keys = [
          {
            key_id = "ed25519:a_HXVM";
            public_key = "4FOGNjNLe3LNGHgDGIMVm3Yx9IQZZnn1LDqv5O1xIns";
          }
        ];
      }
      {
        server_name = "tchncs.de";
        keys = [
          {
            key_id = "ed25519:a_rOPL";
            public_key = "HZxh/ZZktCgLcsJgKw2tHS9lPcOo1kNBoEdeVtmkpeg";
          }
        ];
      }
    ];

    # TODO: shorten this with some map loop magic?
    app_service_api.database.connection_string = db;
    federation_api.database.connection_string = db;
    key_server.database.connection_string = db;
    media_api.database.connection_string = db;
    room_server.database.connection_string = db;
    sync_api.database.connection_string = db;
    user_api.account_database.connection_string = db;
    user_api.device_database.connection_string = db;
    mscs.database.connection_string = db;

    # these are experimental features currently being pull requested
    mscs.mscs = [
      #"msc2836" # threads (client: https://cerulean.matrix.org/)
      "msc2946" # space summary
    ];

    openRegistration = false;
    client_api.registration_disabled = true;
    client_api.guests_disabled = true;

    media_api.max_file_size_bytes = 1073741824;

    # do not enable dynamic thumbnails.
    # these appears to cause a lot of issues. it slows down the homeserver to a crawl and the log is spammed
    # with "signalling other goroutines" stuff. most likely misbehaving and holding things up
    media_api.dynamic_thumbnails = false;

    app_service_api.config_files = [
      #"${dataDir}/matrix-appservice-discord-registration.yaml"
    ];

  };

  # nginx: reverse proxy for matrix and just a general purpose web server

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "francesco149@gmail.com";

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    clientMaxBodySize = "1000M";
  };

  services.nginx.virtualHosts."animegirls.win" = let
      wrk = config.services.matrix-synapse.customWorkers;
      synapseListener = workerName:
        "http://0.0.0.0:${toString (builtins.elemAt wrk.${workerName}.worker_listeners 0).port}";
  in {
    forceSSL = true;
    enableACME = true;

    listen = [
      { port =  443; addr="0.0.0.0"; ssl = true; }
      { port = 8448; addr="0.0.0.0"; ssl = true; }
    ];

    locations."/_matrix".proxyPass = "${synapseLocalUrl}";

    locations."/.well-known/matrix/server".return =
      "200 '{\"m.server\":\"animegirls.win:8448\"}'";

    locations."/.well-known/matrix/client".return =
      "200 '{\"m.homeserver\": {\"base_url\": \"https://animegirls.win\"}}'";

    locations."/_matrix/federation/".proxyPass = synapseListener "federation-reader1";
    locations."~ ^/_matrix/client/.*/(sync|events|initialSync)".proxyPass = synapseListener "client-worker1";

    locations.${builtins.concatStringsSep "" [
      "~ ^/(_matrix/media|_synapse/admin/v1/"
      "(purge_media_cache|(room|user)/.*/media.*|media/.*|quarantine_media/.*|users/.*/media))"
    ]}.proxyPass = synapseListener "media-repo1";
  };

  security.acme.certs."animegirls.win".extraDomainNames = [
    "www.animegirls.win"
    "element.animegirls.win"
  ];

  services.nginx.virtualHosts."element.animegirls.win" = let
    custom-element = pkgs.element-web.override {
      conf = {
        default_server_config = {
          "m.homeserver" = {
            base_url = "https://animegirls.win";
            server_name = "animegirls.win";
          };
        };
        brand = "Anime Girls";
        default_country_code = "US";
        show_labs_settings = true;
        default_theme = "dark";
        room_directory = {
          servers = [
            "animegirls.win"
            "opensuse.org"
            "tchncs.de"
            "libera.chat"
            "gitter.im"
            "matrix.org"
          ];
        };
      };
    };
  in {
    forceSSL = true;
    useACMEHost = "animegirls.win";
    locations."/".root = "${custom-element}";
  };

  services.nginx.virtualHosts."dendrite.animegirls.xyz" = {
    forceSSL = true;
    enableACME = true;
    locations."/".return = "301 $scheme://animegirls.cc$request_uri";
  };

  security.acme.certs."dendrite.animegirls.xyz".extraDomainNames = [
    "animegirls.cc"
  ];

  services.nginx.virtualHosts."animegirls.cc" = {
    forceSSL = true;
    useACMEHost = "dendrite.animegirls.xyz";

    listen = [
      { port =  443; addr="0.0.0.0"; ssl = true; }
      { port = 8420; addr="0.0.0.0"; ssl = true; }
    ];

    locations."/_matrix".proxyPass = dendriteLocalUrl;

    locations."/.well-known/matrix/server".return =
      "200 '{\"m.server\":\"animegirls.cc:8420\"}'";

    locations."/.well-known/matrix/client".return =
      "200 '{\"m.homeserver\": {\"base_url\": \"https://animegirls.cc\"}}'";
  };

  # redirect www to non-www
  services.nginx.virtualHosts."www.animegirls.xyz".locations."/".return =
    "301 $scheme://animegirls.xyz$request_uri";

  services.nginx.virtualHosts."www.animegirls.cc".locations."/".return =
    "301 $scheme://animegirls.cc$request_uri";

  services.nginx.virtualHosts."www.animegirls.win".locations."/".return =
    "301 $scheme://animegirls.win$request_uri";

  networking.hosts."127.0.0.1" = [ "animegirls.xyz" ];

  services.nginx.virtualHosts."animegirls.xyz" = {
    forceSSL = true;
    enableACME = true;

    # TODO: somehow sync this with my own fork of the calculator
    locations."/maple".root = "/web";

    locations."/tix" = {
      root = "/web";

      # TODO: is there a declarative option for this? I couldn't find it
      extraConfig = ''
        allow 192.168.1.0/24;
        allow 127.0.0.1;
        deny all;
      '';
    };

  };

  security.acme.certs."animegirls.xyz".extraDomainNames = [
    "git.animegirls.xyz"
    "lib.animegirls.xyz"
    "vid.animegirls.xyz"
  ];

  # these are TODO. temporary placeholders
  services.nginx.virtualHosts."git.animegirls.xyz" = {
    forceSSL = true;
    useACMEHost = "animegirls.xyz";
    locations."/".root = "/web";
  };

  services.nginx.virtualHosts."lib.animegirls.xyz" = {
    forceSSL = true;
    useACMEHost = "animegirls.xyz";
    locations."/".root = "/web";
  };

  services.nginx.virtualHosts."vid.animegirls.xyz" = {
    forceSSL = true;
    useACMEHost = "animegirls.xyz";
    locations."/".root = "/web";
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
    kbdInteractiveAuthentication = false;
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

    mkSecret = { file, path }: {
      inherit file;
      path = secretPath path;
      symlink = false;
    };

  in {

    dendrite-private-key = mkSecret {
      file = ../secrets/dendrite-keys/matrix_key.pem.age;
      path = "dendrite/matrix_key.pem";
    };

    synapse-homeserver-signing-key = mkSecret {
      file = ../secrets/synapse/homeserver.signing.key.age;
      path = "synapse/homeserver.signing.key";
    };

    synapse-secrets = mkSecret {
      file = ../secrets/synapse/secrets.yaml.age;
      path = "synapse/secrets.yaml";
    };

    matrix-appservice-discord-environment = mkSecret {
      file = ../secrets/matrix-appservice-discord/environment.sh.age;
      path = "matrix-appservice-discord/environment.sh";
    };

    matrix-appservice-discord-registration = mkSecret {
      file = ../secrets/matrix-appservice-discord/registration.yaml.age;
      path = "matrix-appservice-discord/matrix-appservice-discord-registration.yaml";
    };

    gh2md-token = mkUserSecret {
      file = ../secrets/gh2md/token.age;
      path = "/home/${user}/.config/gh2md/token";
    };

    gist-token = mkUserSecret {
      file = ../secrets/gist/token.age;
      path = "/home/${user}/.gist";
    };

  };

}
