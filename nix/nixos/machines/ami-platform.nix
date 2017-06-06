# Barebones NixOS AMI. This module should be included in the NIX_PATH
# with the name "platform" when building AMI images.
# -I platform=.../ami-platform.nix

{config, pkgs, ...}:
{
  imports = [ <nixpkgs/nixos/modules/virtualisation/amazon-image.nix> ];
  ec2.hvm = true;

  # Rerun configuration at init to include new user-data
  systemd.services.custom_init = {
    script = ''
      #!${pkgs.stdenv.shell} -eu

      echo "Reruning nixos-rebuild with new user-data"
      export PATH=${pkgs.lib.makeBinPath [config.system.build.nixos-rebuild]}:$PATH

      nixos-rebuild switch
    '';
    description = "Reconfigure system including EC2 user-data";
    wantedBy = ["multi-user.target"];
    after = ["multi-user.target" ];
    requires = ["network-online.target"];
    restartIfChanged = false;
    unitConfig.X-StopOnRemoval = false;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
