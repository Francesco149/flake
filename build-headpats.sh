#!/bin/sh

nixos-rebuild --flake .#headpats --target-host root@headpats.uk --build-host 192.168.1.4 switch
