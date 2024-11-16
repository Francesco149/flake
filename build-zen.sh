#!/bin/sh

nixos-rebuild --flake .#zen --target-host "root@192.168.1.203" switch
