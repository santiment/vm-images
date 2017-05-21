#!/bin/sh -e

cat >/etc/nixos/platform.nix <<EOF
{config, pkgs, ...}:
{
  imports = [ <nixpkgs/nixos/modules/virtualisation/amazon-image.nix> ];
  ec2.hvm = true;

}
EOF

cat >/etc/nixos/configuration.nix <<EOF
{config, pkgs, ...}:
{
  imports = [./platform.nix];
}
EOF

nix-channel --update
nixos-rebuild switch

# Remove old ssh keys used by packer. Otherwise our instance will not
# be able to read the key provided by amazon during instance creation
rm -rf /root/.ssh
# For the same reason, remove old ec2 metadata
rm -rf /etc/ec2-metadata
