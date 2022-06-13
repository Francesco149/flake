my personal nix flake

# usage

```sh
git clone https://github.com/Francesco149/flake
cd flake
sudo nixos-rebuild switch --flake .?submodules=1#nixos-11400f
```

where nixos-11400f is the name of one of the nixosConfiguration entries in `flake.nix`

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
