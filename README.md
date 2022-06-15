my personal nix flake

# usage (nixos)

```sh
nix-shell -p git --run 'git clone https://github.com/Francesco149/flake ~/flake'
cd ~/flake
nix develop # or nix-shell
git-crypt unlock # or replace the secrets files with your own
nixos-rebuild switch --use-remote-sudo --flake .#nixos-11400f

# relog into your user or reboot
```

where nixos-11400f is the name of one of the nixosConfiguration entries in `flake.nix`

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

edit `configuration.nix` to your liking, you might want to import `../configuration.nix` like my other
configs (see nixos-11400f for an example)

add your own machine configuration to `flake.nix` in nixosConfigurations

```nix
      my-machine = mkSystem {
        configName = "my-machine";
        modules = [ ./my-machine/configuration.nix ];
        homeImports = [ ./home.nix ];
      };
```
