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

# notes about streaming on linux
these are just random notes for myself, things discovered through trial and error

* use a jack input client for virtual sound devices, or whenever possible. do NOT use the pulse
  audio input capture on obs. it will cause choppy audio, especially with a lot of devices.
  I don't know if it's the pipewire pulse compatibility or if it does the same thing on pulse.
  the jack input also makes it easier to manage on carla because it names the obs inputs

* do NOT use the obs video device source for your camera or capture card. use guvcview. it will
  perform much better and load your system much less. even if you switch obs to emulated pixel
  formats, it will still perform much worse than guvcview, not to mention it's more buggy and
  sometimes changing settings will freeze the cam until you restart obs or re-add the source

* pipewire with jack compatibility and carla are a better alternative to voicemeeter on windows.
  you can create as many loopback devices as you want (either through pipewire conf or with
  pulseaudio commands) and route audio to them. carla also allows you to use vst plugins and
  all kinds of stuff. the loopback devices come with a monitor output that you can route to obs
  by creating a jack input client on obs which will appear as a named input on carla

* disabling hardware acceleration in your browser helps avoiding encoder overloads if you're
  pushing your system to its limits

* the low latency quicksync preset seems to stress the encoder much more, and once it gets
  overloaded it can't ever recover and you get really choppy video. normal latency doesn't seem
  to run into this issue even in the event that there is a brief encoder overload

# minipc streaming pc tweaks
* for the n305 beelink mini-pc I use, I like to limit the cpu to 12.5 watts from the BIOS and set
  max igpu frequency to 900 mhz. I've experienced system crashes from the igpu boosting, so
  disable that as well.

* it's possible to do IMON curve and offset tweaks to push past the power limits (which can be
  useful for gaming on low end laptops) but I actually want the opposite.
  I set the PSYS slope to 50 (0.5x) and it seemed to lower temperatures. it also felt like the
  GPU was unstable (I remember reliably crashing with turbo boost enabled for the iGPU). so I
  set its IMON curve to 50 and offset to -7000 as well as raise max voltage to 1.6v to make it
  always run at highest power with a lower max freq which I'm hoping will improve its stability.

* I also disabled spread spectrum. not sure if it affects stability or not but I had a quick
  crash when I tried raising it to 6% from 1.5%

* I replaced the stock 12v 3a psu with a 12v 5a one since I was pretty much constantly maxing
  out the old one and to my surprise, the cpu usage went down and I seem to have more headroom
  than before. it's very possible that the old psu was causing it to throttle itself down due
  to insufficient power delivery. I think I could have it at stock settings with no instability now
