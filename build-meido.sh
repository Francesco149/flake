#!/bin/sh

nixos-rebuild --flake .#meido --target-host root@192.168.1.11 --build-host localhost switch
