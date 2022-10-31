#!/bin/sh

nixos-rebuild --flake .#headpats --target-host root@headpats.uk --build-host root@headpats.uk switch
