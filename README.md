my personal nix flake

# usage

```sh
git clone https://github.com/Francesco149/flake
cd flake
nix develop # or nix-shell
git-crypt unlock # or replace the secrets files with your own
nixos-rebuild switch --use-remote-sudo --flake .#nixos-11400f
```

where nixos-11400f is the name of one of the nixosConfiguration entries in `flake.nix`

whenever you want to rebuild the system, you can simply run the alias `xb` from a shell. the flake must be
located at `~/flake` for this to work

# things to do if you're not me
edit .gitmodules to your own private repo or comment out the private part at the bottom of `home.nix`

```sh
git submodule init
git submodule update --recursive
```

generate your own `hardware-configuration.nix` with `nixos-generate-config` (see nix wiki for more info)
and then copy it

```sh
cp /etc/nixos/hardware-configuration.nix .
```

customize network config in `configuration.nix` and re-enable spectre/meltdown
mitigations in `boot.kernelParams`

create your own machine-specific config. see `config-11400f.nix` as an example.

add your own machine configuration to `flake.nix` in nixosConfigurations

```nix
      my-configuration = mkSystem {
        modules = [./config-my-machine.nix ];
        homeImports = [ ./home.nix ];
      };
```
