#!/bin/sh -e

ROOT=`git rev-parse --show-toplevel`

nixos-rebuild -I nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-17.03.tar.gz\
              -I custom=$ROOT/pkgs\
              -I platform=$ROOT/nixos/machines/ami-platform.nix\
              -I nixos-config=$ROOT/nixos/machines/bastion.nix\
              --target-host root@35.157.123.89\
              --build-host localhost\
              switch
