# Initial configuration.nix file for the generic AMI image

{ config, pkgs, ... }:
{
  imports = [ <nixpkgs/nixos/modules/virtualisation/amazon-image.nix> ];
  santiment.ec2-init.enable = true;
}
