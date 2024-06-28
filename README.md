my personal nix flake

# usage (nixos)

```sh
nix-shell -p git --run 'git clone https://github.com/Francesco149/flake ~/flake'
cd ~/flake
ix-shell -p git --run 'nix --extra-experimental-features nix-command --extra-experimental-features flakes develop' # or nix-shell
nixos-rebuild switch --use-remote-sudo --flake .#tanuki

# relog into your user or reboot
```

where tanuki is the name of one of the nixosConfiguration entries in `flake.nix`

whenever you want to rebuild the system, you can simply run the alias `xb` from a shell. the flake must be
located at `~/flake` for this to work, so you will have to move it if your default user is not the same as
the stock nixos user

# things to do if you're not me
set up your own hardware-specific config

```sh
cd ~/flake
mkdir my-machine
cd my-machine
nixos-generate-config --dir .
```

note: if you're doing this on a remote machine you could simply enable
ssh on its stock `/etc/nixos/configuration.nix` and work on your local
computer by doing:

```
mkdir my-machine
cd my-machine
ssh remotemachine sudo -S nixos-generate-config --show-hardware-config > hardware-configuration.nix
dst='root@remotemachine'
# edit configuration.nix, home.nix, flake.nix etc
nixos-rebuild --flake .#my-machine --target-host $dst --build-host $dst switch
# can also change build-host to localhost if the target is a slow machine
```

edit `configuration.nix` to your liking, you might want to import `../configuration.nix` like my other
configs (see tanuki for an example)

add your own machine configuration to `flake.nix` in nixosConfigurations

```nix
      my-machine = mkSystem {
        configName = "my-machine";
        modules = [ ./my-machine/configuration.nix ];
        homeImports = [ ./home.nix ];
      };
```

edit `secrets/secrets.nix` to have your own ssh key and secrets
