my personal nix flake

# usage

```sh
git clone https://github.com/Francesco149/flake
cd flake
```

if you're not me, edit .gitmodules to your own private repo or comment out the private part at the
bottom of `home.nix`

```sh
git submodule init
git submodule update --recursive
```

if you're not me, generate your own `hardware-configuration.nix` with `nixos-generate-config` ,
see nix wiki for more info and then copy it

```sh
cp /etc/nixos/hardware-configuration.nix .
```

if you're not me, customize network config in `configuration.nix` and re-enable spectre/meltdown
mitigations in `boot.kernelParams`


build and switch to the flake

```sh
sudo nixos-rebuild switch --flake .?submodules=1#
```

# known issues
on boot, you have to `systemctl --user restart emacs` otherwise emacsclient in gui mode won't work

# vim vs emacs?
both, I use vim as a minimal editor when I don't need fancy autocomplete and plugins, and emacs
as a full fat IDE. if I'm writing a familiar language and not using any unfamiliar libraries, then
vim is just fine. otherwise I fire up emacs to speed up the process of exploring stuff with auto
complete
