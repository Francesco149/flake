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
      iface = "eth0";
    };

    streampc = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINqSrHdrIXXD5I8Ho0mCbbGvocmgsGR/ZjWylIUS/cIX loli@streampc";
      print = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtvGlJyJWlTygTiUxhdQEKPz5iOnQDpXq0NoK/fx23oTBYoAM+NxTkK+VMTkSF1E/yVVY2B/HCRrTpf9dKPNE0praYCBcQJYPBWwDVtGI4bOTKm3A7bFxUVxVo0nPVRUHJbZ0rnzyUsUeTD1GLRyYgZm+zyQysK1i/Qurw0yyMNIbvwjZJyr8pdsW6dt/tJRtk743ZNR8u4uPg9tEW2N/R0ZV8HjTOv7a+UAq5P4jFFSULtionQChwhJV4kFAJ/9YQxm2GXU3z0v7/IgK2eqv5yq7DPYHkx1u9y58/FtFGlJXhS7u0xZtX3lsT56Q2cVBb45m8tSro+YNC/gKSYCshuVjzZENbVh+852a+2q90XBVf3pe2j3g3mT9mDPln0OPRaZXf7fZPW7keJQ6gtkBOTfYvAOGe1Rl/nyJMLnUZijxtidQHD9NPbHwEUPWy2b/+IpSilAKLxSUb3ykyZk3VrBeq342ly3QjE9+0tTdX+oFZPL1vIVVnifcwiDqMFhKo+XdqgIS/ZO0nZVEswf/rkiE2nTa9GG/lTJgTVNkMCoyiBy1bvJ8sSUJPRrfu9b3ZgwDc5j4v6U0f1naJvMaITQuf89VnApxIuVIgWfiq6/dk+aFQ7BrxeTcUb0wjLYldetqxvyFL2KAAHBJiK2yR5xSq9S6rB4aV0+S4CLEvTQ== root@streampc";
      ip = mkip 202;
    };

    headpats = {
      key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4j6+dF+4xogE9C7/1Cm67AGslsOPEzCZm8j6WfbEoe7FK1tD3bV9ACjr7mgeCHurKv3IRLZuoQjkyp17c2LwW8hnz0evBnemgrQ3GrTEbYsPl4yJoAuBUdL7HU1DLoq6SlgNxy1lxn5FM5s5t8FH37yFqkvmt6zRoIqsQQ67lBduiNe9wlqskND8t5pckBsNkhot4Otv+Hetpm2lbB+hCo4FLrINZg/dBY5fsngOl5pFw8/Nu+/BdTLluyRgqQEbjFk7mf8AUU530GozTdszGR3gSHOd9vDKOLPWC+HodnV34glUIuTzPCsP7km/oXEDcyWpz2+dJYwsXNLIlRav1qPQ2W2PIduhCeN8NtV3lu2B6h/td+zgkfLkSCxpRokaSsnJCtYhX1GQTEFhWB35QiCwcHzjLf1367ufIrmbdjG1qalqsC0berLG885+Up2L0fFvOp2tH70zR9trTXVi3nnmvKpqamV7yFPClkEGa96hboH4NzIXZit/00LrsDjU= root@headpats";
      print = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCWxWjFDPT0Gu6qi0Byj3TWoSKyxX0H1fm4OxVU6gWzE6mq6DoqlYa1CZwYo4N2k2vDW3YYdRbaiElebcyWrfIc2lLyz5HYZJ5dTzIlicjorwcU+QHtAU2k1wXWKIstEE3HbBXOuJBbEDKopSOBAThvCUQU1C+RcCJrMguis0pXQMlxTyCehNgFvXTFNIWD9dkUAAfsj7r5dlFrIYn1BpyIetWo6yaPQYLi9Cdu4P41dGDSSFuz0uE7l6sqZdKl3Rnbx6/Ay6WAvWjowbsctrFe9IaZMRNX6xNGIgOt8Z6hoItCJqYRELtWXa/Ao2dzyHsvBfw+LCHQ4MgxM9iuLJNMplWRrRvZkHdFi1DZb6nTbL3zZFMn67enhTjn0Olw1MfZ6sjxv37ImLUnDwMOzcjqaa4M60pIjEk+0C/87UdyT6KH2iuLpiuyKP/Vwb6xa5wUIJvrhFokbMyu6xwTIkS978u7EfF7S0sf3qLwPMudvRYdI6cUk4nJ/OwEGbWJlEU= root@headpats";
      ip = "headpats.uk";
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

    # for secrets.nix convenience. machineName -> sshPubKey
    keys = (builtins.listToAttrs (
      map (x: { name = x; value = machines."${x}".key; })
        (builtins.attrNames machines)));
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
