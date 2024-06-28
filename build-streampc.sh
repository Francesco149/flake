#!/bin/sh

dekai="$(nix eval --raw --file ./common/consts.nix machines.dekai.ip)"
streampc="$(nix eval --raw --file ./common/consts.nix machines.streampc.ip)"
nixos-rebuild --flake .#streampc --target-host "root@$streampc" --build-host "root@$dekai" switch
