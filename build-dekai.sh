#!/bin/sh

dekai="$(nix eval --raw --file ./common/consts.nix ips.dekai)"
nixos-rebuild --flake .#dekai --target-host "root@$dekai" --build-host "root@$dekai" switch
