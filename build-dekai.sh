#!/bin/sh

dst='root@192.168.1.4'
nixos-rebuild --flake .#dekai --target-host $dst --build-host $dst switch
