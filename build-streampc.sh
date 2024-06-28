#!/bin/sh

dekai="$(nix eval --raw --file ./common/consts.nix ips.dekai)"
streampc="$(nix eval --raw --file ./common/consts.nix ips.streampc)"
nixos-rebuild --flake .#streampc --target-host "root@$streampc" --build-host "root@$dekai" switch
