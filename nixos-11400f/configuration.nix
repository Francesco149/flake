{ pkgs, user, lib, config, ... }:

let
  pgdb = name: "postgres://${name}@localhost/${name}?sslmode=disable";

  appservice-pgdb = name: {
    engine = "postgres";
    connString = pgdb name;
    filename = "";
  };

  dendriteDomain = "animegirls.cc";
  dendriteLocalPort = 8007;
  dendritePort = 8420;

  synapseDomain = "animegirls.win";
  synapseLocalPort = 8008;
  synapsePort = 8448;

  # can't extract this from dendrite's module it seems. also referencing the systemd service causes inf recursion
  dendriteDataDir = "/var/lib/dendrite";
  ddclientDataDir = "/var/lib/ddclient";

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

  # TODO:
  # if the service has never been started and the data dir does not exist or isn't chowned to the systemd user,
  # this will fail and you will have to chmod manually. I don't have a good solution for that yet. maybe there's
  # a way to put the 2 services into an unit and have that unit run as the same dynamic user?

  serviceFilesWithDir = dataDir: serviceName: files: {
    systemd.services."${serviceName}".after =
      lib.optional config.services.${serviceName}.enable "${serviceName}-serviceFiles.service";
    systemd.services."${serviceName}-serviceFiles" = {
      enable = config.services.${serviceName}.enable;
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
    configFileObj = (synapseWorkerConfig port ({ worker_name = name; } // workerConfig));
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
        LimitNOFILE = 65535;
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

  baseListener = port: resourceNames: extraConfig: {
    inherit port;
    type = "http";
    resources = [{ names = resourceNames; compress = false; }];
  } // extraConfig;

  # generate worker_listeners entry for synapseWorker workerConfig
  synapseWorkerListener = port: resourceNames: baseListener port resourceNames {
    bind_address = "127.0.0.1";
  };

  synapseWorkerListenerConfig = port: resourceNames: workerConfig:
    (synapseWorkerListener port resourceNames) // workerConfig;

  # generate listeners entry for the matrix-synapse service
  synapseListener = port: resourceNames: baseListener port resourceNames {
    bind_addresses = [ "127.0.0.1" ];
    tls = false;
  };

  synapseListenerConfig = port: resourceNames: extraConfig:
    (synapseListener port resourceNames) // extraConfig;

  # generates the .well-known server/client endpoints for a nginx service.

  # usage:
  # imports = [
  #   (matrixNginxWellKnown "example.com" 8448)
  # # ...
  # ]

  matrixNginxWellKnown = domain: port: {
    services.nginx.virtualHosts.${domain} = {
      locations."/.well-known/matrix/server".return = "200 '{\"m.server\":\"${domain}:${toString port}\"}'";
      locations."/.well-known/matrix/client".return =
        "200 '{\"m.homeserver\": {\"base_url\": \"https://${domain}\"}}'";
    };
  };

  # generates the basic nginx config for a matrix server listening on local http port localPort

  # includes:
  # - main /_matrix endpoint
  # - .well-known server/client endpoints for a nginx service
  # - ssl listeners on 443 and port
  # - automatic acme certificate

  # usage:
  # imports = [
  #   (matrixNginx "example.com" 8448 8008)
  # # ...
  # ]

  matrixNginx = domain: port: localPort: {
    imports = [
      (matrixNginxWellKnown domain port)
    ];

    services.nginx.virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;

      listen = [
        { port =  443; addr="0.0.0.0"; ssl = true; }
        { port = port; addr="0.0.0.0"; ssl = true; }
      ];

      locations."/_matrix".proxyPass = "http://localhost:${toString localPort}";
    };
  };

  # convert serviceName into a systemd unit called ${serviceName}.unit .
  # provide extra config such as after= in targetConfig.
  systemdUnit = serviceName: targetConfig: {
    systemd.targets.${serviceName} = {
      description = "${serviceName} processes";
      wantedBy = [ "multi-user.target" ];
    } // targetConfig;
    systemd.services.${serviceName} = {
      partOf = [ "${serviceName}.target" ];
      wantedBy = [ "${serviceName}.target" ];
    };
  };

in
{
  imports = [
    ./hardware-configuration.nix
    ../configuration.nix

    # convert the synapse service into a unit so I can add workers and other dependent services to it
    (systemdUnit "matrix-synapse" {
      after = [ "network.target" "postgresql.service" ];
    })

    (matrixNginx synapseDomain synapsePort synapseLocalPort)
    (matrixNginx dendriteDomain dendritePort dendriteLocalPort)
  ]

  ++ (with config.age.secrets; [
    (serviceFiles "matrix-synapse" [
      synapse-homeserver-signing-key.path
      synapse-secrets.path
      matrix-appservice-discord-registration.path
    ])

    (serviceFilesWithDir dendriteDataDir "dendrite" [
      dendrite-private-key.path
    ])

    (serviceFiles "grafana" [
      grafana-password.path
      grafana-secret-key.path
    ])

    (serviceFilesWithDir ddclientDataDir "ddclient" [
      cloudflare-password.path
    ])
  ])

  ++ [
    # this option is used to store each worker's config obj so I can reuse its values (ports etc) and not repeat
    ({ options.services.matrix-synapse.customWorkers = lib.mkOption { default = {}; }; })

    # NOTE: tls and compression are off by default for workers

    # NOTE: there are things that reference customWorkers that rely on only having 2 worker_listeners
    #       and the metrics worker_listener being the last one in the list.
    #       if I ever need a different setup, I need to change all of those references

    (synapseWorker "federation-sender1" 9101 {
      worker_app = "synapse.app.federation_sender";
    })

    (synapseWorker "federation-reader1" 9102 {
      worker_listeners = [
        (synapseWorkerListenerConfig 8009 [ "federation" ] {
          x_forwarded = true;
        })
      ];
    })

    (synapseWorker "event-persister1" 9103 {
      worker_listeners = [
        (synapseWorkerListener 9091 [ "replication" ])
      ];
    })

    (synapseWorker "client-worker1" 9104 {
       worker_listeners = [
         (synapseWorkerListener 8010 [ "client" ])
       ];
    })

    (synapseWorker "media-repo1" 9105 {
       worker_app = "synapse.app.media_repository";
       worker_listeners = [
         (synapseWorkerListener 8011 [ "media" ])
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
      synapsePort
      dendritePort
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

    svcs = let
      s = name: lib.optionals config.services.${name}.enable name;
    in [
      (s "dendrite")
      (s "matrix-synapse")
      (s "matrix-appservice-discord")
      (s "grafana")
    ];
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
  services.redis.servers."".enable = true;

  # synapse: matrix server
  # nginx is expected to handle https and proxy to the local http

  services.matrix-synapse.enable = true;
  services.matrix-synapse.extraConfigFiles = [
    "${config.services.matrix-synapse.dataDir}/secrets.yaml"
  ];
  systemd.services.matrix-synapse.serviceConfig.LimitNOFILE = 65535;
  services.matrix-synapse.settings = let
    db = pgdb "matrix-synapse";
    dataDir = config.services.matrix-synapse.dataDir;
    wrk = config.services.matrix-synapse.customWorkers;
  in {
    server_name = synapseDomain;
    max_upload_size = "1000M";

    redis.enabled = true;
    send_federation = false;
    enable_media_repo = false;
    enable_metrics = true;

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
    report_stats = false;
    presence.enabled = false;

    app_service_config_files = [
      "${dataDir}/matrix-appservice-discord-registration.yaml"
    ];

    database = {
      name = "psycopg2";
      args.host = "localhost";
    };

    listeners = let
      s = synapseListener;
      c = synapseListenerConfig;
    in [
      (c synapseLocalPort [ "client" "federation" ] {
        x_forwarded = true;
      })
      (s 9093 [ "replication" ])
      (c 9009 [ "metrics" ] {
        type = "metrics";
      })
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

  # bridges and other matrix appservices

  services.matrix-appservice-discord = {
    enable = true;
    environmentFile = config.age.secrets.matrix-appservice-discord-environment.path;

    settings.bridge = {
      domain = synapseDomain;
      homeserverUrl = "https://${synapseDomain}";
      enableSelfServiceBridging = true;
      disableJoinLeaveNotifications = true;
      disableInviteNotifications = true;
    };

    # crashes the bridge for some reason, so disabled
    settings.metrics = {
      enable = false;
      port = 9201;
      host = "127.0.0.1";
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
    global.server_name = dendriteDomain;
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
    clientMaxBodySize = "1000M"; # for big matrix uploads
  };

  # matrixNginx takes care of most things, but we have to configure the worker endpoints here

  services.nginx.virtualHosts.${synapseDomain} = let
      wrk = config.services.matrix-synapse.customWorkers;
      synapseListener = workerName:
        "http://127.0.0.1:${toString (builtins.elemAt wrk.${workerName}.worker_listeners 0).port}";
  in {
    locations."/_matrix/federation/".proxyPass = synapseListener "federation-reader1";
    locations."~ ^/_matrix/client/.*/(sync|events|initialSync)".proxyPass = synapseListener "client-worker1";

    locations.${builtins.concatStringsSep "" [
      "~ ^/(_matrix/media|_synapse/admin/v1/"
      "(purge_media_cache|(room|user)/.*/media.*|media/.*|quarantine_media/.*|users/.*/media))"
    ]}.proxyPass = synapseListener "media-repo1";

    # other things hosted at the synapse domain
    locations."/maple".root = "/web";

    locations."/tix" = {
      root = "/web";

      # NOTE: firefox seems to ignore my hosts settings and still 403, but it does work
      extraConfig = ''
        allow 192.168.1.0/24;
        allow 127.0.0.1;
        deny all;
      '';
    };
  };

  # allow access to private paths by making it a local request
  networking.hosts."127.0.0.1" = [ synapseDomain ];

  security.acme.certs.${synapseDomain}.extraDomainNames = [
    "www.${synapseDomain}"
    "element.${synapseDomain}"
  ];

  services.nginx.virtualHosts."element.${synapseDomain}" = let
    custom-element = pkgs.element-web.override {
      conf = {
        default_server_config = {
          "m.homeserver" = {
            base_url = "https://${synapseDomain}";
            server_name = synapseDomain;
          };
        };
        brand = "Anime Girls";
        default_country_code = "US";
        show_labs_settings = true;
        default_theme = "dark";
        room_directory = {
          servers = [
            synapseDomain
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
    useACMEHost = synapseDomain;
    locations."/".root = "${custom-element}";
  };

  # prometheus: monitoring tool, only used for matrix for now
  services.prometheus = let
    wrk = config.services.matrix-synapse.customWorkers // {
      master.worker_listeners = config.services.matrix-synapse.settings.listeners;
    };
  in {
    enable = true;
    globalConfig.scrape_interval = "5s";
    scrapeConfigs = [
      {
        job_name = "synapse";
        metrics_path = "/_synapse/metrics";

        static_configs = lib.mapAttrsToList (name: value: {

          targets = with builtins; let
            metricsListeners = filter (x: x.type == "metrics") value.worker_listeners;
            port = if length metricsListeners > 0 then (elemAt metricsListeners 0).port else -1;
          in [ "127.0.0.1:${toString port}" ];

          labels = { instance = synapseDomain; job = name; index = "1"; };

        }) wrk;
      }
      {
        job_name = "matrix-appservice";
        metrics_path = "/metrics";
        static_configs = let
          svc = x: lib.optionals config.services.${x}.enable x;
        in map (job: {
          targets = [ "127.0.0.1:${toString config.services.${job}.settings.metrics.port}" ];
          labels = { instance = synapseDomain; inherit job; };
        }) [
          (svc "matrix-appservice-discord")
        ];
      }
    ];

    ruleFiles = [
      (pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/matrix-org/synapse/0fed46ebe5abc524f10708ce1d5849e53dbab8af/contrib/prometheus/synapse-v2.rules";
        sha256 = "0d8jvlrp3f3y6wkrw6qvdvmd6k8zj46cg7qiz44gr1hs4s00grg9";
      })
    ];
  };

  # grafana: fancy interface for the prometheus synapse metrics
  services.grafana = {
    enable = true;

    security = let
      dataDir = config.services.grafana.dataDir;
    in {
      adminPasswordFile = "${dataDir}/password";
      secretKeyFile = "${dataDir}/secret-key";
    };

    # use postgresql
    database = {
      type = "postgres";
      host = "127.0.0.1";
      user = "grafana";
    };

    provision = {
      enable = true;

      dashboards = let
        d = name: path: { inherit name path; };
        f = name: url: sha256: d name (pkgs.fetchurl { inherit url sha256; });
      in map (x: {
        name = x.name;
        type = "file";
        folder = "Server";
        options.path = x.path;
      }) [

        (f "synapse"
          "https://github.com/matrix-org/synapse/blob/77258b67257983d67f90270d3d8e04594fd512ba/contrib/grafana/synapse.json"
          "19r9vpvg7x29agnnj4wsfizvl0s7famzfspypibalygq1mdc2pn2")

        (f "appservice"
          "https://raw.githubusercontent.com/matrix-org/matrix-appservice-irc/9ada0c2477d63f040d7c49d16d12b7ac3a044f72/contrib/grafana.json"
          "0vg7g1slqp0hhkk0bq6vkvmlbbkgjh44qwj5kwyqc84lpkmgjilv")

      ];

      datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          access = "proxy";
          isDefault = true;
          jsonData = {
            timeInterval = config.services.prometheus.globalConfig.scrape_interval;
          };
        }
      ];

    };
  };

  # redirect www to non-www
  services.nginx.virtualHosts."www.${dendriteDomain}".locations."/".return =
    "301 $scheme://${dendriteDomain}$request_uri";

  services.nginx.virtualHosts."www.${synapseDomain}".locations."/".return =
    "301 $scheme://${synapseDomain}$request_uri";

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
    kbdInteractiveAuthentication = false;
  };

  services.ddclient = rec {
    enable = true;
    server = "cloudflare.com";
    username = "francesco149@gmail.com";
    passwordFile = "${ddclientDataDir}/password";

    domains = [
      dendriteDomain
      synapseDomain
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

    grafana-secret-key = mkSecret {
      file = ../secrets/grafana/secret-key.age;
      path = "grafana/secret-key";
    };

    grafana-password = mkSecret {
      file = ../secrets/grafana/password.age;
      path = "grafana/password";
    };

    gh2md-token = mkUserSecret {
      file = ../secrets/gh2md/token.age;
      path = "/home/${user}/.config/gh2md/token";
    };

    gist-token = mkUserSecret {
      file = ../secrets/gist/token.age;
      path = "/home/${user}/.gist";
    };

    cloudflare-password = mkSecret {
      file = ../secrets/cloudflare/password.age;
      path = "cloudflare/password";
    };

  };

}
