my personal nix flake

# usage (nixos)

```sh
nix-shell -p git --run 'git clone https://github.com/Francesco149/flake ~/flake'
cd ~/flake
ix-shell -p git --run 'nix --extra-experimental-features nix-command --extra-experimental-features flakes develop' # or nix-shell
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
configs (see nixos-11400f for an example)

add your own machine configuration to `flake.nix` in nixosConfigurations

```nix
      my-machine = mkSystem {
        configName = "my-machine";
        modules = [ ./my-machine/configuration.nix ];
        homeImports = [ ./home.nix ];
      };
```

edit `secrets/secrets.nix` to have your own ssh key and secrets

# known issues
cachix will not apply until after the first rebuild-switch. this means that nix will attempt to build emacs from scratch for example.
the workaround is to temporarily set the emacs package to just emacs in `home.nix` and then change it back

# emacs vs vim
I mainly use vim. I only use emacs to write notes and such in org-mode. I tried using emacs for
programming and as a window manager with exwm for a couple months, but it's just too slow and
janky. there were times where opening large source files (nothing crazy, not even in the megabytes)
would make emacs unbearably slow in movement and editing, even with tree-sitter.
this is why my emacs config has font-lock disabled by default.
I only enable it when I know it's not gonna be slow.  vim has no such problems out of the box.

other problems I had with emacs were situations where I could softlock emacs by doing unexpected
things like mousing over a different window while being in some evil or minibuffer prompt, in some
cases I just wasn't able to get out of it because not even M-x was working.

I don't need IDE features like autocomplete, they actually slow me down. I tried using fancy
language servers and such, it just makes writing code more painful for me. most of the time it
either breaks my flow or just doesn't do what I expect it to do
