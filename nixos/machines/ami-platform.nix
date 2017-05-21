# Barebones NixOS AMI. This module should be included in the NIX_PATH
# with the name "platform" when building AMI images.
# -I platform=.../ami-platform.nix

{config, pkgs, ...}:
{
  imports = [ <nixpkgs/nixos/modules/virtualisation/amazon-image.nix> ];
  ec2.hvm = true;
}
