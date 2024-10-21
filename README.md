# setting up a new machine remotely
if you're not me, edit `machines/dummy/configuration.nix` to not have the ssh and mitigations
settings and set up your own so you don't give me access to your machine.

on the main machine, set up a directory in the flake for the new machine

```sh
cp -R ~/flake/machines/{dummy,mymachine}
```

on the target machine, clone the repo and build the dummy flake

```sh
nix-shell -p git
git clone https://github.com/Francesco149/flake ~/flake
cd ~/flake
nixos-generate-config --show-hardware-config > machines/dummy/hardware-configuration.nix
git add machines/dummy/hardware-configuration.nix
nixos-rebuild switch --use-remote-sudo --flake .#dummy
scp machines/dummy/hardware-configuration.nix mainmachine:flake/machines/mymachine/
```

from the main machine, edit `flake.nix` and `machines/mymachine/configuration.nix`

check the bottom of `/etc/nixos/configuration.nix` on the target machines and copy the stateVersion
line to your `configuration.nix`

now you can remotely build the target machine (see for example `build-streampc.sh`)

# setting up a new machine
set up your own hardware-specific config (nixos-generate-config must be run on the target machine)

```sh
cd ~/flake
cp -R ~/flake/machines/{dummy,mymachine}
nixos-generate-config --show-hardware-config > machines/mymachine/hardware-configuration.nix
```

edit `machines/mymachine/configuration.nix` to your liking. you probably want to remove the
ssh and mitigations configs as they would give me access to your machine and make it insecure

check the bottom of `/etc/nixos/configuration.nix` and copy the stateVersion line to your
`configuration.nix`

add your own machine configuration to `flake.nix` in nixosConfigurations

```nix
      sys "mymachine" unstable // # or hmsys if you want home-manager
```

if you use home-manager, edit `machines/mymachine/home.nix` . see other machines
for reference (`common/desktop/home.nix` for example)

if you have any files you want to encrypt in the repo, edit `secrets/secrets.nix` to have your own
ssh key and secrets

# building from a fresh nixos install on the target machine
note: you would only do this if you're on the actual specific machine that you're building
(tanuki in this example)

```sh
nix-shell -p git --run 'git clone https://github.com/Francesco149/flake ~/flake'
cd ~/flake
nixos-rebuild switch --use-remote-sudo --flake .#tanuki

# reboot
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

# startup checklist for streampc
this is to remind myself

* select "music visualizer out" on the kiosk firefox for the music visualizer if prompted
* start the music with `mus https://youtube...`
* reload `stream-linux.carxp` on carla
* might have to re-connect the music visualizer out to firefox. for some reason it doesn't automatically restore the connection
* make sure audio is fine on obs

# known issues

this is somewhat of a TODO list for myself

* if anything causes the 2nd monitor to be disconnected, obs crashes and the visualizer glitches.
  find a way to ensure that the display is always there even if disconnected
