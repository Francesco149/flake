{ pkgs, lib, ... }:
let
  consts = import ../consts.nix;

  # TODO: i can get the domains from here
  #services.adguardhome.settings.dns.rewrites =
  #  lib.pipe config.services.lancache.domainIndex [
  #    (map (entry: entry.domains))
  #    lib.flatten
  #    (map (domain: { inherit domain; answer = lancacheServerIp; }))
  #  ]

  lancacheDomains = let
    d = x: y: { name = x; sha256 = y; };
  in map (service: pkgs.fetchurl {
    url = "https://github.com/uklans/cache-domains/raw/refs/heads/master/${service.name}.txt";
    inherit (service) sha256;
  }) [
    # (d "name" lib.fakeSha256 )
    (d "arenanet" "sha256-ab927cj5Uihdps2YMiDRFnCQbw/NdGfwf/1NVFOZHzM=" )
    (d "blizzard" "sha256-LIP8srO7Gg2qW+ORhFfGQMerLMd7VZRoOkGAR3kd4E0=" )
    (d "epicgames" "sha256-MpqODHAOXsdAWbX8TZXoFCPjSmKwvRz2Dn/Jn9qDzhs=" )
    (d "steam" "sha256-Zd9AU8rBpcnCiB26RnVaYVaY/3qDcOzRQCcUW+qEd1g=" )
    (d "rockstar" "sha256-hvEQdLi7NBw7lBxlQgqYW3NuF41arW8oOLunrTLJ9IQ=" )
    (d "sony" "sha256-3sbdEbb4wHqL2PR3zIJ+H7lwkR4051vcTEgRr614IYA=" )
    (d "nexusmods" "sha256-UamIHvoP00+TlTHAcfHGz4uaycdzdq/2gCtWPqXzOSk=" )
    (d "nintendo" "sha256-MAB7qqEanlANjYbHV1cbuY20FxpGs/8oJkoT3omq0X4=" )
    (d "uplay" "sha256-DuZ+uXne3shDHq5HSqHD8++0QvsPDqR/6Xywp7g4oxQ=" )
    (d "xboxlive" "sha256-qnyNE/fZcDtc7QlKFA5+cLBJf4jD/6sn4pKoDCKXUFA=" )
    (d "warframe" "sha256-S2VpJsQlm1cclv/4dThazI9NTLsnnf9p1M87viIdKNI=" )
  ];
in {
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;
      listen_addresses = [ "[::1]:51" ];

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

      cloaking_rules = with builtins; pkgs.writeText "dnscrypt-cloak" (
        (lib.strings.concatStringsSep "\n"
          (concatMap (domainList:
            (map
              (domain: "${domain} ${consts.lancacheIp}")
              (lib.strings.splitString "\n"
                (readFile domainList))))
                lancacheDomains))
      );
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };

  networking = {
    nameservers = [ "127.0.0.1" "::1" ];
    networkmanager.dns = "none";
    dhcpcd.extraConfig = "nohook resolv.conf";
  };

  services.resolved.enable = false;

  # Forward loopback traffic on port 53 to dnscrypt-proxy2.
  networking.firewall.extraCommands = ''
    ip6tables --table nat --flush OUTPUT
    ${lib.flip (lib.concatMapStringsSep "\n") [ "udp" "tcp" ] (proto: ''
      ip6tables --table nat --append OUTPUT \
        --protocol ${proto} --destination ::1 --destination-port 53 \
        --jump REDIRECT --to-ports 51
    '')}
  '';
}
