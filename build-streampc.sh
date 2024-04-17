#!/bin/sh

dst='root@192.168.1.202'
nixos-rebuild --flake .#streampc --target-host $dst --build-host $dst switch
