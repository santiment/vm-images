#!/bin/sh -e
# Partition disk
cat <<FDISK | fdisk /dev/sda
n




a
w
FDISK

# Create filesystem
mkfs.ext4 -j -L nixos /dev/sda1

# Mount filesystem
mount LABEL=nixos /mnt

# Setup system
nixos-generate-config --root /mnt

cat >/mnt/etc/nixos/platform.nix <<NIX
# Virtualbox-specific image configuration
{config, pkgs, ...}:

{
  imports = [./hardware-configuration.nix];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  virtualisation.virtualbox.guest.enable = true;

  boot.initrd.checkJournalingFS = false;
}
NIX

cat >/mnt/etc/nixos/configuration.nix <<NIX
{ config, pkgs, ... }:

{
  imports = [./platform.nix];
}
NIX

### Install ###
nixos-install
