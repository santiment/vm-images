#!/usr/bin/env nix-shell
#!nix-shell '<nixpkgs>' -p bash git jq awscli -i bash

ROOT=`git rev-parse --show-toplevel`
NIX=$1

PRIVATE_IPS=`aws ec2 describe-instances\
               --filters "Name=tag:Nix,Values=${NIX}"\
                         "Name=tag:Environment,Values=stage" |\
             jq --raw-output\
               '.Reservations | map(.Instances | map(.PrivateIpAddress)) | flatten | join("\n")'`

for IP in $PRIVATE_IPS; do
    echo "Updating IP $IP"
    NIX_SSHOPTS="-J root@$BASTION" nixos-rebuild -I nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-17.03.tar.gz\
           -I custom=$ROOT/pkgs\
           -I platform=$ROOT/nixos/machines/ami-platform.nix\
           -I nixos-config=$ROOT/nixos/machines/${NIX}.nix\
           --build-host localhost --target-host root@${IP}\
           switch
done
