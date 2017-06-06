#!/bin/sh

ROOT=`git rev-parse --show-toplevel`

nixos-rebuild -I nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-17.03.tar.gz\
              -I custom=$ROOT/pkgs\
              -I terraform=$ROOT/terraform.json\
              -I platform=$ROOT/nixos/machines/ami-platform.nix\
              -I nixos-config=$ROOT/nixos/machines/trollbox-client.nix\
              --target-host root@ec2-52-29-142-124.eu-central-1.compute.amazonaws.com\
              switch --show-trace
