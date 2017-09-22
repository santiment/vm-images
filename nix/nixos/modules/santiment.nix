{config, pkgs, lib, ...}:
{
  imports = [./elasticsearch-main.nix
             ./consul.nix
	     ./btce-client.nix
	     ./sanbase-website.nix
	     ];
}
