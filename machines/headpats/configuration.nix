{ pkgs, config, ... }:
let
  release = "nixos-24.05";
  headpatsDomain = "headpats.uk";
in
{
  imports = [
    ./hardware-configuration.nix
    (builtins.fetchTarball {
      url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/archive/${release}/nixos-mailserver-${release}.tar.gz";
      sha256 = "sha256:0clvw4622mqzk1aqw1qn6shl9pai097q62mq1ibzscnjayhp278b";
    })
  ];

  system.stateVersion = "22.05";
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "headpats";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpNgs8JFiW2okM8bWoQXkXD6y3x1LONA3hNQbUmvJhMK8BP7Ajkd5avC0dhyOnHee1WCoiQfCfqN/2SVgHMDmRv2QNluciZ4scFr1IwXRxrUqRPpDid6bBIc/e7PYcFBfA2r1nfOdZTePiQcQAcb0yhblqtsg9aOgl+JwqK4GvoQgwriB3Hp6PrezRYBcQjjLbcrU8U1vqKCljhL/cYy5qj5ybJ4hRYcsuZoiQxjtomlrsmibVcTJZVnwPL3DVhCcNrPYABstVgLZfLSttCQCdB2VvGJOx5r6gaB8bkgHsqgERyZza4hBYsMPLSuzxrxgEH+AZzTBGIZiWD0WgY+81 loli@void"
  ];

  # automatically garbage collect nix store to save disk space
  nix.gc.automatic = true;
  nix.gc.dates = "03:15";

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "francesco149@gmail.com";

  # temporary workaround for nixos 24.05
  # https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/issues/275
  services.dovecot2.sieve.extensions = [ "fileinto" ];

  mailserver = {
    enable = true;
    fqdn = "mail.${headpatsDomain}";
    domains = [ headpatsDomain ];

    # nix shell nixpkgs\#apacheHttpd -c htpasswd -nbB "" "wow super secret pass" | cut -d: -f2
    loginAccounts = with config.age.secrets; {
      "loli@${headpatsDomain}" = {
        hashedPasswordFile = loli-hashed-password.path;
        aliases = [ "postmaster@${headpatsDomain}" ];
      };
    };

    enableManageSieve = true; # enables filters using sieve scripts

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = "acme-nginx";
  };

  security.acme.certs.${headpatsDomain}.extraDomainNames = [
    "rain.${headpatsDomain}" # used to be rainloop, unused now because fuck all that php config
    "cube.${headpatsDomain}"
  ];

  services.nginx.enable = true;

  services.nginx.virtualHosts."${headpatsDomain}" = {
    # TODO some landing page or some shit
    forceSSL = true;
    enableACME = true;
  };

  services.roundcube = {
    enable = true;
    hostName = "cube.${headpatsDomain}"; # nginx vhost for the web mail
    plugins = [ "managesieve" ];
    extraConfig = ''
      # starttls needed for authentication, so the fqdn required to match
      # the certificate
      $config['smtp_server'] = "tls://${config.mailserver.fqdn}";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
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
      loli-hashed-password = mkSecret {
        file = ../../secrets/headpats/loli-hashed-password.age;
        path = "loli/hashed-password";
      };
    };
}

