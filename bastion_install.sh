#!/bin/sh -e

ROOT=/tmp
nixos-rebuild -I nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-17.03.tar.gz\
              -I custom=$ROOT/pkgs\
              -I platform=$ROOT/nixos/machines/ami-platform.nix\
              -I nixos-config=$ROOT/nixos/machines/bastion.nix\
              switch

nix-collect-garbage -d
rm -rf /tmp/*

# Remove old ssh keys used by packer. Otherwise our instance will not
# be able to read the key provided by amazon during instance creation
rm -rf /root/.ssh
# For the same reason, remove old ec2 metadata
rm -rf /etc/ec2-metadata
