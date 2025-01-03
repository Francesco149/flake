# various common constants that I use in multiple places

let
  pre = "192.168.1.";
  mkip = x: "${pre}${toString x}";
in
rec {
  user = "loli";
  system = "x86_64-linux";
  lancacheIp = mkip 5;

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

      domains = builtins.listToAttrs (
        map (x: { name = x; value = "${x}.local"; })
          [
            "cloud"
            "office"
          ]
      );
    };

    streampc-beelink-eq20-pro = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINqSrHdrIXXD5I8Ho0mCbbGvocmgsGR/ZjWylIUS/cIX loli@streampc";
      print = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtvGlJyJWlTygTiUxhdQEKPz5iOnQDpXq0NoK/fx23oTBYoAM+NxTkK+VMTkSF1E/yVVY2B/HCRrTpf9dKPNE0praYCBcQJYPBWwDVtGI4bOTKm3A7bFxUVxVo0nPVRUHJbZ0rnzyUsUeTD1GLRyYgZm+zyQysK1i/Qurw0yyMNIbvwjZJyr8pdsW6dt/tJRtk743ZNR8u4uPg9tEW2N/R0ZV8HjTOv7a+UAq5P4jFFSULtionQChwhJV4kFAJ/9YQxm2GXU3z0v7/IgK2eqv5yq7DPYHkx1u9y58/FtFGlJXhS7u0xZtX3lsT56Q2cVBb45m8tSro+YNC/gKSYCshuVjzZENbVh+852a+2q90XBVf3pe2j3g3mT9mDPln0OPRaZXf7fZPW7keJQ6gtkBOTfYvAOGe1Rl/nyJMLnUZijxtidQHD9NPbHwEUPWy2b/+IpSilAKLxSUb3ykyZk3VrBeq342ly3QjE9+0tTdX+oFZPL1vIVVnifcwiDqMFhKo+XdqgIS/ZO0nZVEswf/rkiE2nTa9GG/lTJgTVNkMCoyiBy1bvJ8sSUJPRrfu9b3ZgwDc5j4v6U0f1naJvMaITQuf89VnApxIuVIgWfiq6/dk+aFQ7BrxeTcUb0wjLYldetqxvyFL2KAAHBJiK2yR5xSq9S6rB4aV0+S4CLEvTQ== root@streampc";
      ip = mkip 202;
    };

    zen = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINqSrHdrIXXD5I8Ho0mCbbGvocmgsGR/ZjWylIUS/cIX loli@streampc";
      print = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCkEmB97CA5rkCZeVzu0cA2uALbfNkXsq4x3by7+fyeI8Lrbl1y2mC+9+Lfo7rfbNg9MZu6Bx1l+IVwJlJmk0Y7r8Vya524ZTWG1IV3mt5dPjkzhfaPIHi/E/A9XS85CflRclZyVpTILDit+k19ozb3d/97cZy0qGy2U0NpuCB+hTjF8aRWviKpxfraKOMV+TTMiMfjJook3vlQQOhw/HRHB34BSTLUrCH6kTp017uehsvko0fM6+Nqa27jmgl1bBxXI2wyImcHiE0VejwxgEIRLfog/Y58Wd7C/DIpgb84YK+WNhVN0dK9ChAa9KnV47ALMDpQiBCMUCoQUJN2HaKTcUljQyPE7dM4sFp/M0rqssxdStAtE7tDHc8Kvd3pEgiUtDWts7S4T04MCGq0aGwHWfyRxfq/KE4/ofBlzmqpuZZltd9RaYtsWuTAojkqbuv5dslO2mqkvlUfCm/wBiryJqigvxKrymHJBwNEYEoQ0+WttKShACFsa6U+BfFLTGEh6eevi1/gMFaZNgYzn0/GcGWfq7Ai1rk0fFR73hQorcIBv1yqO4RjDFqoir36LGdJWM1Y45KI1Aq5DP5bFnet9JcH+aSgu30UTZ0lYaBL/qo/K/S7w6Ls/md79eJ3u6g9+RfeczI9AWwy29NLO5Nhdu+j+V5dtD/JSOQZj2B+3Q== root@streampc";
      ip = mkip 203;
    };

    streampc-5900x = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINqSrHdrIXXD5I8Ho0mCbbGvocmgsGR/ZjWylIUS/cIX loli@streampc";
      print = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCTuIF+Qf0QjEjtkrqPH+PxF5fOQwOz4x15CU/psvCAJfCfryE3acb5GC89hIrnygrhO+2PCmkJ5dEmWm0cEPEA6Bt0sfBH1Yt5a2pulTKx5ngfNkRRseAuXQ6Wcumbuy7BFhrBMJIsrLFnzzFF8BGM02juEuGBloqQXc6oh48cLA6KrpL8zJEzr6Xos7VnS2FtkXx/0JOP8prTtUERH/GlVUi6fCD7rstPyOrf574KQDYL1V8YDPcYNSzGHabdunt4BF5+Szyi+ljFy1HnDzx/QiZXP0ZP33o5w8ztZ6CYYGJePxozJN4iYe0s3ufC1EYFoOqkj8blESpDYXWRbsS1kf78yFTQirvE6sJV1VCRWZxIDuuob/6Hz1TH4ItlgfFmRWxJYocQ7Uc5T9swVb1QVmhQjguUJJcJgU0G6Xl9CDhrfFrdCxS4Wqjm6MpHsxE68sOswIrrmE+2okdNFvN3MNVhH3EZQ9aOCFnZf2DwnxYuyXG8bT5rgWwdpBXKtEF8KsRdtvbxyNtasmnDIY8UJTmFq2PzU5oj2ew/zd+UVZqZI5WY86XwczD+0iBy7khOFLAgikujync/mM4h5W0slKFIHf4lxXkPf/WF39u7OpardVAfZeElHXV74WW6vS009r9vcb1iTNQHjINK6BVkfdYQJFIw8+/gb5tk+dHLEQ== root@nixos";
      ip = mkip 202;
    };

    streampc-11400f = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINqSrHdrIXXD5I8Ho0mCbbGvocmgsGR/ZjWylIUS/cIX loli@streampc";
      print = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYP+SInNB6tzWdyZwRl6Vf0A9A57CnWETAUWQLwpaDeY6Tql+Qk4lLcy3mGVh8p66WDhWPQQXMEz5cO3pywS4I3wY4n/X86gzxwSXbS0yzqCrqzTAyJVcTvW+zsJNLVi1s6XFBz2iFjfxT2KgReausllmGrGHw9rNMYhPNXtbHxGxDkPD4v5T3sLI97f2wP/Sx88E6Sln6TDndIUMUbMlMmGl0Dnlf9LwdMZshoBIkTDf0+BM0Z/NeufJ6m9L/JE9WYZF6yHwtkbm/EK/LnpLU2wz4W0C9d4TVt9/x7rwpHlP85Y3jxHrPi9eezuTSTz15+UA31hCN0/tgaJi3X4Yujp6+GI4bLdwdLVqcq5gflJMo0D7VJBzAe36+E94LopBOMRsoj272FxUyD1+F/LGts6FhYT2twhQkmpxUXV3R+t0LdpFrbmlePRX8j0kGP9T9P0I0jcWKEkgmXpuUWOLAzWbFee2ZREQ/Xh1y47BQ0NCHBs7o7oIVxzTcE7b/O/ILFLX94Wp7fyVmhNOiLfs8KvFDN1v0KHHwko/NMp4v2N83MNmD8jf7qcEHLfKw8017MHzGxUu9O2ZGBRNNHV/bLsK029EZU0K0/Fs8onkwMRdjrBP8UDpZ6e3s+Y4FZPrUUTl4dXDjUdeBVQEoKaWgTDbXdmISkBpd44VF3OW9FQ== root@nixos";
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
