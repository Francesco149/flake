#!/bin/sh

dekai="$(nix eval --raw --file ./common/consts.nix machines.dekai.ip)"
meido="$(nix eval --raw --file ./common/consts.nix machines.meido.ip)"
nixos-rebuild --flake .#meido --target-host "root@$meido" --build-host "$dekai" switch
