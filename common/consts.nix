rec {
  user = "loli";
  system = "x86_64-linux";

  ips =
    let
      pre = "192.168.1.";
      i = x: "${pre}${toString x}";
    in
    {
      inherit pre;
      mask = "${i 0}/24";
      gateway = i 1;
      dekai = i 4;
      streampc = i 202;
      meido = i 11;
    };

  nginx = {
    localOnly = {
      # NOTE: firefox seems to ignore my hosts settings and still 403, but it does work
      extraConfig = ''
        allow ${ips.mask};
        allow 127.0.0.1;
        deny all;
      '';
    };
  };
}
