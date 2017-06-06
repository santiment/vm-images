#!/usr/bin/env nix-shell
#!nix-shell '<nixpkgs>' -p bash git jq awscli -i bash

ROOT=`git rev-parse --show-toplevel`
NIX=$1

RESULTS=`aws ec2 describe-instances\
               --filters "Name=tag:Nix,Values=${NIX}"\
                         "Name=tag:Environment,Values=stage" |\
             jq --raw-output\
               '.Reservations | map(.Instances | map([.PrivateIpAddress, .InstanceId] | join(","))) | flatten | join("\n")'`

echo $RESULTS
for RES in $RESULTS; do
    arrIN=(${RES//,/ })
    IP=${arrIN[0]}
    INSTANCE_ID=${arrIN[1]}
    echo "Updating Private IP $IP"
    echo "Instance id $INSTANCE_ID"

    #Get userdata
    rm -rf ./user-data
    RAWUSERDATA=`aws ec2 describe-instance-attribute --instance-id ${INSTANCE_ID} --attribute userData`
    echo "$RAWUSERDATA"
    EXTRACTED=`echo "$RAWUSERDATA" | jq --raw-output '.UserData.Value?'`
    echo "$EXTRACTED"
    if [ "$EXTRACTED" == "null" ]; then
        echo "No user-data"
        touch ./user-data
    else
        DECODED=`echo "$EXTRACTED"| base64 -d`
        echo "$DECODED" > ./user-data
    fi

    NIX_SSHOPTS="-J root@$BASTION" nixos-rebuild -I nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-17.03.tar.gz\
           -I custom=$ROOT/nix/pkgs\
           -I platform=$ROOT/nix/nixos/machines/ami-platform.nix\
           -I nixos-config=$ROOT/nix/nixos/machines/${NIX}.nix\
           -I user-data=./user-data\
           --build-host localhost --target-host root@${IP}\
           switch
done
