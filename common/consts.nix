# various common constants that I use in multiple places

let
  pre = "192.168.1.";
  mkip = x: "${pre}${toString x}";
in rec {
  user = "loli";
  system = "x86_64-linux";

  machines = {
    tanuki = {
      key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpNgs8JFiW2okM8bWoQXkXD6y3x1LONA3hNQbUmvJhMK8BP7Ajkd5avC0dhyOnHee1WCoiQfCfqN/2SVgHMDmRv2QNluciZ4scFr1IwXRxrUqRPpDid6bBIc/e7PYcFBfA2r1nfOdZTePiQcQAcb0yhblqtsg9aOgl+JwqK4GvoQgwriB3Hp6PrezRYBcQjjLbcrU8U1vqKCljhL/cYy5qj5ybJ4hRYcsuZoiQxjtomlrsmibVcTJZVnwPL3DVhCcNrPYABstVgLZfLSttCQCdB2VvGJOx5r6gaB8bkgHsqgERyZza4hBYsMPLSuzxrxgEH+AZzTBGIZiWD0WgY+81 loli@void";
    };

    dekai = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMoAHQaYnRdHSRw6spSVSrEH1aeRX85iuYlV/MuLpolZ loli@nixos";
      ip = mkip 4;
    };

    streampc = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINqSrHdrIXXD5I8Ho0mCbbGvocmgsGR/ZjWylIUS/cIX loli@streampc";
      ip = mkip 202;
    };

    meido = {
      key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/qT1HTLf42+VbCKQwUUIJ+LVPGguIzezJqcgqaeOiU/qLJQOchMArtpZ92yVoEBOdu8wQ851jWeDsKjNqhe/6vycPDFRDBrUVtzQPifLM5ZeV8rjdsr/TPIwht7KR7goXu5scWrvvhX4cNALfxnMjWxzRjHIBMRxNkqENl70+mnuBrLIc4TFN+BgSPy0OVTEqJlfiPh7wqwzI//6YUTR0labODLlxUilXabZIOV+b1U4lzzBSBkUB3ExYw7G3ae5yUKu+CdacWDjkRujg7RIA0LgaZr4uTbW6AUsCSReNTH7W7EOdhsCau9XXADLJlaG6lOIOzGvNH9RoFW1Id3chG4jJ9BO2Np4PIzIDT6X6NFcTS3L/ZjAdPAaLo6kAnO34TGLz/p6q0Vt7uNhx56KTtCrxVdGAv5r9JcGxOlzNEBd8OrK3sQ1SJKEIUXnv06jLaMPDrmWR1k3o3OrJ5lJyGJTJQKDdxd5jFek9OwI0l6UCA3ua4KWugYBkX0ScGbM= root@meido";
      ip = mkip 11;
    };
  };

  ssh = with builtins; rec {
    # any machine that has a fixed ip will be added to the known hosts with its respective ssh key
    knownHosts = listToAttrs (
      map (x: { name = "${x.ip}"; value.publicKey = x.key; } )
      (filter (x: hasAttr "ip" x)
        (attrValues machines))
    );
    authorizedKeys = with machines; map (x: x.key) [
      tanuki
      dekai
    ];
  };

  ips = {
    inherit pre;
    mask = "${mkip 0}/24";
    gateway = mkip 1;
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
