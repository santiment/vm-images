{config, pkgs, ...}:
{
  imports = [<platform> ../modules/sanbase-website.nix];

  services.sanbase-website.enable = true;
}
