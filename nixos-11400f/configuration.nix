{ pkgs, user, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../configuration.nix
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

  services.postgresql = {
    enable = true;
    # package = pkgs.postgresql_14;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE dendrite WITH LOGIN PASSWORD 'dendrite' NOCREATEDB;
      CREATE DATABASE dendrite;
      GRANT ALL PRIVILEGES ON DATABASE dendrite TO dendrite;
    '';
  };

  # dendrite: matrix server

  # we don't need to run it in https mode because nginx does the job of handling https requests,
  # providing the cert and redirecting the connection to the local http port

  services.dendrite = {
    enable = true;
    httpPort = 8008;
  };

  # the dendrite service runs with DynamicUser, meaning systemd creates a user dynamically for it.
  # this gives that user access to these files that wouldn't have correct ownership otherwise

  systemd.services.dendrite.serviceConfig.PermissionsStartOnly = true;

  systemd.services.dendrite.preStart = lib.mkAfter ''

    install -m 400 /var/lib/dendrite/matrix_key.pem /run/dendrite/matrix_key.pem
    chown -R $(stat -c %u /run/dendrite) /run/dendrite

  '';

  services.dendrite.settings = let
    db = "postgres://dendrite@localhost/dendrite?sslmode=disable";
  in {
    global.server_name = "animegirls.cc";
    global.private_key = "/run/dendrite/matrix_key.pem";

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
    media_api.dynamic_thumbnails = true;
    media_api.max_thumbnail_generators = 10;
    media_api.thumbnail_sizes = [
      { width = 32; height = 32; method = "crop"; }
      { width = 96; height = 96; method = "crop"; }
      { width = 640; height = 480; method = "scale"; }
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

    locations."/_matrix".proxyPass = "http://localhost:8008";

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

  services.nginx.virtualHosts."animegirls.xyz" = {
    forceSSL = true;
    enableACME = true;

    # TODO:
    locations."/maple".root = "/web";
    #locations."/tix".root = "/web"; # TODO: this should be private
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

  in {

    dendrite-private-key = {
      file = ../secrets/dendrite-keys/matrix_key.pem.age;
      path = "/var/lib/dendrite/matrix_key.pem";
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
