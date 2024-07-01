{ config, pkgs, lib, user, ... }:


let
  consts = import ../../common/consts.nix;
  inherit (consts.ssh) authorizedKeys;

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

  synapseFederationReceiverPort = 8009;
  synapseClientWorkerPort = 8010;
  synapseMediaRepoPort = 8011;

  # can't extract this from dendrite's module it seems. also referencing the systemd service causes inf recursion
  dendriteDataDir = "/var/lib/dendrite";

  # serviceFilesWithDir generates a service that runs as root and installs files into the service's
  # data directory with correct ownership for a DynamicUser service.
  # they will be read-only for the user.  this is meant for secrets.

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
            --owner $(stat -c %u "${dataDir}/") \
            --group $(stat -c %g "${dataDir}/") \
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
        { port = 443; addr = "0.0.0.0"; ssl = true; }
        { port = port; addr = "0.0.0.0"; ssl = true; }
      ];

      locations."/_matrix".proxyPass = "http://localhost:${toString localPort}";
    };
  };

in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../common/nix/configuration.nix
      ../../common/locale/configuration.nix
      ../../common/dnscrypt/configuration.nix

      (matrixNginx synapseDomain synapsePort synapseLocalPort)
      (matrixNginx dendriteDomain dendritePort dendriteLocalPort)
    ]
    ++ (with config.age.secrets; [
      (serviceFilesWithDir dendriteDataDir "dendrite" [
        dendrite-private-key.path
      ])

      (serviceFiles "matrix-synapse" [
        synapse-homeserver-signing-key.path
        synapse-secrets.path
      ])
    ]);

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-901be401-55e0-4047-a286-bb53898060de".device = "/dev/disk/by-uuid/901be401-55e0-4047-a286-bb53898060de";

  networking = {
    hostName = "dekai";
    hostId = "09952a93";
    usePredictableInterfaceNames = false;
    useDHCP = false;

    # allow access to private paths by making it a local request
    hosts."127.0.0.1" = [ synapseDomain ];

    interfaces."${consts.machines.dekai.iface}".ipv4.addresses = [{
      address = consts.machines.dekai.ip;
      prefixLength = 24;
    }];

    defaultGateway = {
      interface = consts.machines.dekai.iface;
      address = consts.ips.gateway;
    };

    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
        22 # ssh
        80 # http
        443 # https
        synapsePort
        dendritePort
        5357 # wsdd, for samba win10 discovery
        8000 # archivebox
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
    }
    )
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

      # archivebox and dependencies. archives web pages locally
      archivebox
      single-file-cli
      nodejs

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

  services.postgresql =
    let
      db = name: {
        inherit name;
        ensureDBOwnership = true;
      };

      # steps to migrate dendrite database from one machine to the other
      # # enable postgre on destination machine with initialScript
      # # disable any services using the database
      # pg_dump -C -U dendrite dendrite | ssh root@destination psql -U dendrite dendrite
      # sudo rsync -avz /var/lib/private/dendrite root@destination:/var/lib/private
      # # enable dendrite on other machine
      svcs = [
        "matrix-synapse"
        "dendrite"
      ];
    in
    {
      enable = true;
      enableTCPIP = true;

      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
      '';

      ensureDatabases = svcs;
      ensureUsers = map (x: (db x)) svcs;

      # using collation other than C can cause subtle corruption in your indices if libc/icu changes stuff.
      # this script recreates template1, the default database template, to have collation C
      # https://www.citusdata.com/blog/2020/12/12/dont-let-collation-versions-corrupt-your-postgresql-indexes/

      initialScript = pkgs.writeText "postgres-initial" ''
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
    };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "francesco149@gmail.com";

  security.acme.certs.${synapseDomain}.extraDomainNames = [
    "www.${synapseDomain}"
    "element.${synapseDomain}"
    "hydrogen.${synapseDomain}"
    "maple.${synapseDomain}"
  ];

  services.cloudflare-dyndns = {
    enable = true;
    apiTokenFile = config.age.secrets.cloudflare-password.path;
    domains = [
      dendriteDomain
      synapseDomain
    ];
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    clientMaxBodySize = "1000M"; # for big matrix uploads
  };

  # matrixNginx takes care of most things, but we have to configure the worker endpoints here

  services.nginx.virtualHosts.${synapseDomain} =
    let
      localListener = port: "http://127.0.0.1:${toString port}";
    in
    {
      locations."/_matrix/federation/" = {
        proxyPass = localListener synapseFederationReceiverPort;
      };

      locations."~ ^/_matrix/client/.*/(sync|events|initialSync)" = {
        proxyPass = localListener synapseClientWorkerPort;
      };

      locations.${builtins.concatStringsSep "" [
        "~ ^/(_matrix/media|_synapse/admin/v1/"
        "(purge_media_cache|(room|user)/.*/media.*|media/.*|quarantine_media/.*|users/.*/media))"
      ]} = {
        proxyPass = localListener synapseMediaRepoPort;
      };
    };

  services.nginx.virtualHosts."test.local".locations."/" = {
    proxyPass = "http://0.0.0.0:6969";
    inherit (consts.nginx.localOnly) extraConfig;
  };

  services.nginx.virtualHosts."element.${synapseDomain}" =
    let
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
    in
    {
      forceSSL = true;
      useACMEHost = synapseDomain;
      locations."/".root = "${custom-element}";
    };

  services.nginx.virtualHosts."hydrogen.${synapseDomain}" = {
    forceSSL = true;
    useACMEHost = synapseDomain;
    locations."/".root = "${pkgs.hydrogen-web}";
  };

  # redirect www to non-www
  services.nginx.virtualHosts."www.${dendriteDomain}".locations."/".return =
    "301 $scheme://${dendriteDomain}$request_uri";

  services.nginx.virtualHosts."www.${synapseDomain}".locations."/".return =
    "301 $scheme://${synapseDomain}$request_uri";

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

  services.dendrite.settings =
    let
      dataDir = dendriteDataDir;

      dbConf = {
        connection_string = pgdb "dendrite";
        max_open_conns = 10;
        max_idle_conns = 2;
        conn_max_lifetime = -1;
      };
    in
    {
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
      app_service_api.database = dbConf;
      federation_api.database = dbConf;
      key_server.database = dbConf;
      media_api.database = dbConf // { max_open_conns = 5; };
      room_server.database = dbConf;
      sync_api.database = dbConf;
      user_api.account_database = dbConf;
      user_api.device_database = dbConf;
      mscs.database = dbConf // { max_open_conns = 5; };

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

  # redis: just used by matrix now. used for inter-process communication
  services.redis.servers."".enable = true;

  # synapse: matrix server
  # nginx is expected to handle https and proxy to the local http

  services.matrix-synapse.enable = true;
  services.matrix-synapse.extraConfigFiles = [
    "${config.services.matrix-synapse.dataDir}/secrets.yaml"
  ];
  systemd.services.matrix-synapse.serviceConfig.LimitNOFILE = 65535;

  services.matrix-synapse.workers =
    let
      lc = res: port: config: {
        worker_listeners = [
          {
            inherit port;
            type = "http";
            bind_addresses = [ "127.0.0.1" ];
            tls = false;
            resources = [{
              names = [ res ];
            }];
          }
        ];
      };
      l = res: port: lc res port { };
    in
    {
      "federation_sender" = { };
      "federation_receiver" = (lc "federation" synapseFederationReceiverPort { x_forwarded = true; });
      "event_persister" = (l "replication" 9091);
      "client_worker" = (l "client" synapseClientWorkerPort);
      "media_repo" = (l "media" synapseMediaRepoPort);
    };

  services.matrix-synapse.settings =
    let
      db = pgdb "matrix-synapse";
      dataDir = config.services.matrix-synapse.dataDir;
      wrk = config.services.matrix-synapse.customWorkers;
    in
    {
      server_name = synapseDomain;
      max_upload_size = "1000M";

      redis.enabled = true;
      enable_metrics = true;

      # these have good defaults already but I just wanna ensure they stick even if the default changes
      enable_registration = false;
      registration_shared_secret = null;
      macaroon_secret_key = null;
      report_stats = false;
      presence.enabled = false;

      database = {
        name = "psycopg2";
        args.host = "localhost";
      };

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

  services.matterbridge = {
    enable = true;
    configPath = config.age.secrets.matterbridge-config.path;
  };


  services.pantalaimon-headless = {
    instances = {
      animegirls-win = {
        homeserver = "https://animegirls.win";
        listenAddress = "127.0.0.1";
        listenPort = 20662;
        ssl = false;
      };
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

      dendrite-private-key = mkSecret {
        file = ../../secrets/dendrite-keys/matrix_key.pem.age;
        path = "dendrite/matrix_key.pem";
      };

      synapse-homeserver-signing-key = mkSecret {
        file = ../../secrets/synapse/homeserver.signing.key.age;
        path = "synapse/homeserver.signing.key";
      };

      synapse-secrets = mkSecret {
        file = ../../secrets/synapse/secrets.yaml.age;
        path = "synapse/secrets.yaml";
      };

      cloudflare-password = mkSecret {
        file = ../../secrets/cloudflare/password.age;
        path = "cloudflare/password";
      };

      matterbridge-config = mkSecret
        {
          file = ../../secrets/matterbridge/config.toml.age;
          path = "matterbridge/config.toml";
        } // {
        owner = "matterbridge";
      };

    };

  system.stateVersion = "23.11";

}
