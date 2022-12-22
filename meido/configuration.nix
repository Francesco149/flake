{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # Enable swap on luks
  boot.initrd.luks.devices."luks-ac66aa94-2a1a-47f5-b6a1-d4cf2f14a2b4".device = "/dev/disk/by-uuid/ac66aa94-2a1a-47f5-b6a1-d4cf2f14a2b4";
  boot.initrd.luks.devices."luks-ac66aa94-2a1a-47f5-b6a1-d4cf2f14a2b4".keyFile = "/crypto_keyfile.bin";

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";

  # automatically garbage collect nix store to save disk space
  nix.gc.automatic = true;
  nix.gc.dates = "03:15";

  # don't wanna get stuck in emergency mode over benign errors
  systemd.enableEmergencyMode = false;

  networking = {
    hostName = "meido";
    usePredictableInterfaceNames = false;
    nameservers = [ "127.0.0.1" "::1" ];
    defaultGateway = "192.168.1.1";
    resolvconf.enable = false;
    dhcpcd.enable = false;
  };

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };

      # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
      # server_names = [ ... ];
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };

  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.1.11";
    prefixLength = 24;
  }];

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpNgs8JFiW2okM8bWoQXkXD6y3x1LONA3hNQbUmvJhMK8BP7Ajkd5avC0dhyOnHee1WCoiQfCfqN/2SVgHMDmRv2QNluciZ4scFr1IwXRxrUqRPpDid6bBIc/e7PYcFBfA2r1nfOdZTePiQcQAcb0yhblqtsg9aOgl+JwqK4GvoQgwriB3Hp6PrezRYBcQjjLbcrU8U1vqKCljhL/cYy5qj5ybJ4hRYcsuZoiQxjtomlrsmibVcTJZVnwPL3DVhCcNrPYABstVgLZfLSttCQCdB2VvGJOx5r6gaB8bkgHsqgERyZza4hBYsMPLSuzxrxgEH+AZzTBGIZiWD0WgY+81 loli@void"
  ];

  system.stateVersion = "22.11";

}
