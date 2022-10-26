{ pkgs, config, user, ... }:
let
  release = "nixos-22.05";
  headpatsDomain = "headpats.uk";
  rainloopDataDir = "/var/lib/rainloop";
  rainloopUser = "rainloop";
in {
  imports = [
    ./hardware-configuration.nix
    (builtins.fetchTarball {
      url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/archive/${release}/nixos-mailserver-${release}.tar.gz";
      sha256 = "sha256:0csx2i8p7gbis0n5aqpm57z5f9cd8n9yabq04bg1h4mkfcf7mpl6";
    })
  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "headpats";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpNgs8JFiW2okM8bWoQXkXD6y3x1LONA3hNQbUmvJhMK8BP7Ajkd5avC0dhyOnHee1WCoiQfCfqN/2SVgHMDmRv2QNluciZ4scFr1IwXRxrUqRPpDid6bBIc/e7PYcFBfA2r1nfOdZTePiQcQAcb0yhblqtsg9aOgl+JwqK4GvoQgwriB3Hp6PrezRYBcQjjLbcrU8U1vqKCljhL/cYy5qj5ybJ4hRYcsuZoiQxjtomlrsmibVcTJZVnwPL3DVhCcNrPYABstVgLZfLSttCQCdB2VvGJOx5r6gaB8bkgHsqgERyZza4hBYsMPLSuzxrxgEH+AZzTBGIZiWD0WgY+81 loli@void" 
  ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "francesco149@gmail.com";

  mailserver = {
    enable = true;
    fqdn = "mail.${headpatsDomain}";
    domains = [ headpatsDomain ];

    # nix shell nixpkgs\#apacheHttpd -c htpasswd -nbB "" "wow super secret pass" | cut -d: -f2
    loginAccounts = with config.age.secrets; {
      "loli@${headpatsDomain}" = {
        hashedPasswordFile = loli-hashed-password.path;
        aliases = ["postmaster@${headpatsDomain}"];
      };
    };

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = 3;
  };

  security.acme.certs.${headpatsDomain}.extraDomainNames = [
    "rain.${headpatsDomain}"
  ];

  services.nginx.enable = true;
  services.nginx.virtualHosts."${headpatsDomain}" = {
    # TODO some landing page or some shit
    forceSSL = true;
    enableACME = true;
  };

  # TODO: this requires manually creating /var/lib/rainloop and chmodding it.
  #       how do I automate that?
  services.nginx.virtualHosts."rain.${headpatsDomain}" = {
    forceSSL = true;
    useACMEHost = headpatsDomain;
    locations."/" = {
      root = "${pkgs.rainloop-community}";
      index = "index.php";
    };
    extraConfig = ''client_max_body_size 50m;'';
    locations."~ \.php$" = {
      root = "${pkgs.rainloop-community}";
      extraConfig = ''
        fastcgi_pass  unix:${config.services.phpfpm.pools.rainloop.socket};
        fastcgi_index index.php;
        include       ${pkgs.nginx}/conf/fastcgi.conf;
      '';
    };
  };

  users.users.${rainloopUser} = {
    isSystemUser = true;
    description = "Rainloop user";
    createHome = true;
    home = rainloopDataDir;
    group = "rainloop";
  };

  users.groups.rainloop = {};

  services.phpfpm.pools.rainloop = {
    user = rainloopUser;
    settings = {
      "env[RAINLOOP_DATA_DIR]" = rainloopDataDir;
      pm = "dynamic";
      "listen.owner" = config.services.nginx.user;
      "pm.max_children" = 5;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 3;
      "pm.max_requests" = 500;
    };
    phpOptions = ''
      upload_max_filesize = 40m
      post_max_size = 49M
    '';
  };

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      22 # ssh
      80 # http
      443 # https
    ];
  };

  age.identityPaths = [
    "/root/.ssh/id_rsa"
  ];

  age.secrets = let
    secretPath = path: "/var/lib/secrets/${path}";
    mkSecret = { file, path }: {
      inherit file;
      path = secretPath path;
      symlink = false;
    };
  in {
    loli-hashed-password = mkSecret {
      file = ../secrets/headpats/loli-hashed-password.age;
      path = "loli/hashed-password";
    };
  };
}

