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

in
{
  imports = [
    ./hardware-configuration.nix
    ../configuration.nix
  ];

  system.stateVersion = "22.05";

  nix = {
    package = pkgs.nixVersions.unstable;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    settings.trusted-users = [ "root" user ];
  };

  programs.mtr.enable = true;

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

  # try to optimize power consumption
  boot.kernel.sysctl = {
    "kernel.nmi_watchdog" = 0;
    "vm.dirty_writeback_centisecs" = 6000;
    "vm.laptop_mode" = 5;
  };

  powerManagement = {
     powertop.enable = true;
     scsiLinkPolicy = "med_power_with_dipm";
   };

  # spin down disks after 21mins
  powerManagement.powerUpCommands = ''
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K3PNERFU
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K2EJP002
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K3PNE22D
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K4ES2R9F
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K6DV1X2V
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K0HP5XTS
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K3ACZK44
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K2EJY0NR
  '';


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

  # automatically garbage collect nix store to save disk space
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

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
      5357 # wsdd, for samba win10 discovery
    ];
    allowedUDPPorts = [
      3702 # wsdd, for samba win10 discovery
      53 # local dns
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

    svcs =  [
      "matrix-synapse"
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
