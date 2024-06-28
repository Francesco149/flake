#!/bin/sh

dekai="$(nix eval --raw --file ./common/consts.nix ips.dekai)"
meido="$(nix eval --raw --file ./common/consts.nix ips.meido)"
nixos-rebuild --flake .#meido --target-host "root@$meido" --build-host "$dekai" switch
