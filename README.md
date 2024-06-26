# setting up a new machine
set up your own hardware-specific config

```sh
cd ~/flake
mkdir machines/my-machine
cd machines/my-machine
nixos-generate-config --dir .
```

note: if you're doing this on a remote machine you could simply enable
ssh on its stock `/etc/nixos/configuration.nix` and work on your local
computer by doing:

```
mkdir machines/my-machine
cd machines/my-machine
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
      sys "my-machine" unstable // # or hmsys if you want home-manager
```

if you use home-manager, create and edit `machines/my-machine/home.nix` . see other machines
for reference (tanuki for example)

edit `secrets/secrets.nix` to have your own ssh key and secrets

# building from a fresh nixos install on the target machine
note: you would only do this if you're on the actual specific machine that you're building
(tanuki in this example)

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
