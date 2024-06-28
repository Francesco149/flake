#!/bin/sh

git ls-tree --full-tree -r --name-only HEAD | grep .nix$ | xargs nixpkgs-fmt
