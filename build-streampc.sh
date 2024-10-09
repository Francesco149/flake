#!/bin/sh

streampcip="$(nix eval --raw --file ./common/consts.nix machines.streampc-5900x.ip)"
nixos-rebuild --flake .#streampc-5900x --target-host "root@$streampcip" switch
