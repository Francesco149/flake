#!/bin/sh

dekai="$(nix eval --raw --file ./common/consts.nix machines.dekai.ip)"
streampcip="$(nix eval --raw --file ./common/consts.nix machines.streampc-beelink-eq20-pro.ip)"
# --build-host "root@$dekai"
nixos-rebuild --flake .#streampc-beelink-eq20-pro --target-host "root@$streampcip" switch
