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

  services.openssh.enable = true;
  users.extraUsers.root.openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLdgzhoLTiW1bEwuwJX0E1kCIZT0ZbCk/jtnbynbtPAaM2ARX66MwK+dGZrEfK51b2OyBf7ZV4AbdeRpR/KXWkwV1eJcbP7Tv07mCorw2YzKq5hEkQasoKMoOlLR78cRNOnsOGn/c5vZNAiX8S4x1efRnkq9EAKrtcCR5McqcFn/47UTy9n+FkABuST2o+Vdw+tYWvF2xLBNgeFsRd3WzZrZs7YFUTlamv3PZ7fQhvgK2auwxYb+6aAxkRU1q+K0aEhZ9myj0S1SF0A2Tz4ebhcPUde/Gdn5BHQJToQoxBYW4taJHNnd616MqjLCWuod48SxwlpwdPDtVcWpKUxN2x vagrant@nixbox" ];
}
EOF

nix-channel --update
nixos-rebuild switch

#Remove old ssh keys
rm -rf /root/.ssh
