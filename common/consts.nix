# various common constants that I use in multiple places

let
  pre = "192.168.1.";
  mkip = x: "${pre}${toString x}";
in
rec {
  user = "loli";
  system = "x86_64-linux";

  machines = {
    tanuki = {
      key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpNgs8JFiW2okM8bWoQXkXD6y3x1LONA3hNQbUmvJhMK8BP7Ajkd5avC0dhyOnHee1WCoiQfCfqN/2SVgHMDmRv2QNluciZ4scFr1IwXRxrUqRPpDid6bBIc/e7PYcFBfA2r1nfOdZTePiQcQAcb0yhblqtsg9aOgl+JwqK4GvoQgwriB3Hp6PrezRYBcQjjLbcrU8U1vqKCljhL/cYy5qj5ybJ4hRYcsuZoiQxjtomlrsmibVcTJZVnwPL3DVhCcNrPYABstVgLZfLSttCQCdB2VvGJOx5r6gaB8bkgHsqgERyZza4hBYsMPLSuzxrxgEH+AZzTBGIZiWD0WgY+81 loli@void";
      print = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDkv1OyYpZEirOEkv4jxIolu1r7eMOen1Qmy01H2iiGzGdvygLIygNl4N8PpvEt6hNDOXvzzkRxc0POgTucN3Bg2z5Z7anxqGy1TWajYqaXBoIwN9Awj7D+h9dGhWP3boT5E6F5QcuBr6YjmTk8hnV7BKLBE9bwhajaTKZ/uR0HDomTodBf2nUxhxboKJo0VuCEgvJALHO7WrQmfSj45DYwLqwZ5LwvsKXYXWhEyOw9GytvTCHgBMLfcBfakW+ig853Hs9ej8UD6cS6R/Fivt/xGHoCyb9UUqMxRlAMlNJlQCAmOgZzXjAITGAsJJmVtdGM4N57NGxaZEAAdN/0/CoLDFji7KJOTbaym9KAqf1mThtNKFSodOpJsWHcpWzRwpqIb6nmicUy32ZjeZMFu+T0aOduwixgy9wGdd8xMFwksZADEta5i2G1WqQHWpTa88WOh3tuuon78Ei7TcDcosnqyR0ETZws0DSjhc0HtkW9sf7acdEjxIrTUhOPI4vLuQqYXJb/ji+cbKmPNc3eZJ+lC163reVuycwJOWDcpAzxqNQIZzqvg8CJCgNq431buoJ7UQuZWgd6/+0ICL3AAFQdv0/bGcEAPqIhVOEaYsT3vBu+x7xI73swBtF9RBrs0FOM/99VzSyl779m7zeEddRdqPeQNT5R90e9C4eGaW0Alw== root@tanuki";
    };

    dekai = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMoAHQaYnRdHSRw6spSVSrEH1aeRX85iuYlV/MuLpolZ loli@nixos";
      print = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCPEDxFgoqXmI5JBEfaH6J+WghwQQ12XUhfOYb6I2PrAI5pOpDcnFRYbzZz9BfLuZrUAz0xX2/lglsv9ThaxPSqxOHJ72IKxDt8geJ7ecIPFKmutXivRWK2zjrKOMsKr1sq49qDs6QyCQOgVsqE8YBwcahnRmny0tq9lcVY5YX8H5sz7WuOJJI+BzczJHCnv44aZdFUAIwMbDQ2/cDR8KZuMNGmJ9MIU6x5yzDXO8BNbebRJKQlnp75c1xd1Ynd695qbdYLgVSX2y9sV5vEjlfOa7PffNeO5JSGf8EVWAN3pi3Wp0Y5Zz369vsK7hbr9uGm8gQSxHQN3qcdUM91TmJP/aZa8lFlDGd3lPXOOM2f4Ib/Z4W90l03ABjSt7M3eCgLV9jbfB5quRWsIU0a3KYgXePyPp2lUIuZuFpX5lMfkm4nWLBFkRXJhSyTxwnVd3evqGKIhrwFtpOaDlozdRbB+8PwssvDyHbsUu/WFv6O+4Af7UXlLwzFcSab/+zljUcOzln2B9vtzdhzFXkY4C/2HZleXsC+832haAWqQlKKrGZUGswh6Xs4hbu99YsZu1wPs+hxCsqUcqJ+MNgSOgNpp8NbmVQupaoqNrXghZKOfI+Dm2Z9yHjrm4p+PBFwbldaNX3h35P6n0Un8ihzcQfbJkXZY1anvgwXZhj2vgrQtw== root@nixos";
      ip = mkip 4;
    };

    streampc = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINqSrHdrIXXD5I8Ho0mCbbGvocmgsGR/ZjWylIUS/cIX loli@streampc";
      print = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtvGlJyJWlTygTiUxhdQEKPz5iOnQDpXq0NoK/fx23oTBYoAM+NxTkK+VMTkSF1E/yVVY2B/HCRrTpf9dKPNE0praYCBcQJYPBWwDVtGI4bOTKm3A7bFxUVxVo0nPVRUHJbZ0rnzyUsUeTD1GLRyYgZm+zyQysK1i/Qurw0yyMNIbvwjZJyr8pdsW6dt/tJRtk743ZNR8u4uPg9tEW2N/R0ZV8HjTOv7a+UAq5P4jFFSULtionQChwhJV4kFAJ/9YQxm2GXU3z0v7/IgK2eqv5yq7DPYHkx1u9y58/FtFGlJXhS7u0xZtX3lsT56Q2cVBb45m8tSro+YNC/gKSYCshuVjzZENbVh+852a+2q90XBVf3pe2j3g3mT9mDPln0OPRaZXf7fZPW7keJQ6gtkBOTfYvAOGe1Rl/nyJMLnUZijxtidQHD9NPbHwEUPWy2b/+IpSilAKLxSUb3ykyZk3VrBeq342ly3QjE9+0tTdX+oFZPL1vIVVnifcwiDqMFhKo+XdqgIS/ZO0nZVEswf/rkiE2nTa9GG/lTJgTVNkMCoyiBy1bvJ8sSUJPRrfu9b3ZgwDc5j4v6U0f1naJvMaITQuf89VnApxIuVIgWfiq6/dk+aFQ7BrxeTcUb0wjLYldetqxvyFL2KAAHBJiK2yR5xSq9S6rB4aV0+S4CLEvTQ== root@streampc";
      ip = mkip 202;
    };

    meido = {
      key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/qT1HTLf42+VbCKQwUUIJ+LVPGguIzezJqcgqaeOiU/qLJQOchMArtpZ92yVoEBOdu8wQ851jWeDsKjNqhe/6vycPDFRDBrUVtzQPifLM5ZeV8rjdsr/TPIwht7KR7goXu5scWrvvhX4cNALfxnMjWxzRjHIBMRxNkqENl70+mnuBrLIc4TFN+BgSPy0OVTEqJlfiPh7wqwzI//6YUTR0labODLlxUilXabZIOV+b1U4lzzBSBkUB3ExYw7G3ae5yUKu+CdacWDjkRujg7RIA0LgaZr4uTbW6AUsCSReNTH7W7EOdhsCau9XXADLJlaG6lOIOzGvNH9RoFW1Id3chG4jJ9BO2Np4PIzIDT6X6NFcTS3L/ZjAdPAaLo6kAnO34TGLz/p6q0Vt7uNhx56KTtCrxVdGAv5r9JcGxOlzNEBd8OrK3sQ1SJKEIUXnv06jLaMPDrmWR1k3o3OrJ5lJyGJTJQKDdxd5jFek9OwI0l6UCA3ua4KWugYBkX0ScGbM= root@meido";
      print = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCcNr5q2BS7La3aC6Y+VPF98RHi0KK5WeqkrEfjzJ/PTcmEeK5KNyLVQiIHmaCaf9ojqkf8nAiLrtguy6P9ABZJg6c4NK0xVj9gDoIko7SbGSXjmaeq3Gbd5tZVc0PNO1PlVSLEtcxYANhUN6D9AqF3dQAYHDWaVGor5bxg8e6rFN7EQNpyt2ljK7pseP8zLOz9wSRlOQM89W3RtKqDhomG3L99+B7Oq6F+Vf3RGIdxUTS7sJRk3SuhsIlppI+DO6s2CYve270CItX4j/JwdVTCTEgvUiBaqmR2/j33LB3M5881tcV0S4GB5eWtWns3O6W6ZafbhZjf1vWPpkZewY0uv7Un3Oe/rGdHHnegZM+SzrmP7GlSLN/eBbuDpHvfDcOaWqcopSBIR/6isxchCyfNmQxhez6zK/UyTsUn2hPhkwsn4Q0/ubhpZYZ2mIl71l9yt1q99HvDEw9qXKn8jcoC9W5yqF2rHA3URsdsn03NVigqbQedXA8MLJMw9tM0r3vU+g0UckK0CexR58dSalzDH65+wM3S6W250hqzNvYtqXh7Nx9BcnFoQMObKNZOxlWDUbPIb7TKmsMcF3/qbYp+bkqC56kNoaoBZsCmkjjRALQmEB8bCVX0ZUktUPBznb5bchR3PDRBgMNNlfknjJNfXyejMbMi3T2z7geruePrew== root@meido";
      ip = mkip 11;
    };
  };

  ssh = with builtins; rec {
    # any machine that has a fixed ip will be added to the known hosts with its ssh print
    knownHosts = listToAttrs (
      map (x: { name = "${x.ip}"; value.publicKey = x.print; })
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
