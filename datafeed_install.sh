#!/bin/sh -e

#!/bin/sh -e

# Download the channel
curl -L https://github.com/NixOS/nixpkgs-channels/archive/nixos-17.03.tar.gz >/nixpkgs.tar.gz
tar -zxf /nixpkgs.tar.gz
mv nixpkgs-channels-nixos-17.03 /nixpkgs


mkdir -p /custom
tar -zxf /custompkgs.tar.gz -C /custom

# Configuration
cat >/etc/nixos/configuration.nix <<EOF

{config, pkgs, ...}:
{
  customNixPathStr="nixpkgs=/nixpkgs:custom=/custom/nix/pkgs:platform=/custom/nix/nixos/machines/ami-platform.nix:nixos-config=/etc/nixos/configuration.nix:user-data=/etc/ec2-metadata/user-data";
  nix.nixPath=["nixpkgs=/nixpkgs" "custom=/custom/nix/pkgs" "platform=/custom/nix/nixos/machines/ami-platform.nix" "nixos-config=/etc/nixos/configuration.nix" "user-data=/etc/ec2-metadata/user-data"];

  imports = [ /custom/nix/nixos/machines/datafeed-client.nix];
}
EOF

# Initial user-data
cat >/etc/ec2-metadata/user-data <<EOF
{
  "elasticsearchHost" : "localhost"
}
EOF

nixos-rebuild -I nixpkgs=/nixpkgs\
           -I custom=/custom/nix/pkgs\
           -I platform=/custom/nix/nixos/machines/ami-platform.nix\
           -I nixos-config=/etc/nixos/configuration.nix\
           -I user-data=/etc/ec2-metadata/user-data\
           switch

nix-collect-garbage -d

# Remove old ssh keys used by packer. Otherwise our instance will not
# be able to read the key provided by amazon during instance creation
rm -rf /root/.ssh
# For the same reason, remove old ec2 metadata
rm -rf /etc/ec2-metadata
