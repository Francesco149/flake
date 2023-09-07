#!/bin/sh

nixos-rebuild --flake .#streampc --target-host root@192.168.1.8 --build-host localhost switch
