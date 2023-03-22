#!/bin/sh

nixos-rebuild --flake .#tanuki --target-host root@192.168.1.4 --build-host localhost switch
