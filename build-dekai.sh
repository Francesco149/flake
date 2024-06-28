#!/bin/sh

dekai="$(nix eval --raw --file ./common/consts.nix machines.dekai.ip)"
nixos-rebuild --flake .#dekai --target-host "root@$dekai" --build-host "root@$dekai" switch
