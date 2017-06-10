# Barebones NixOS AMI. This module should be included in the NIX_PATH
# with the name "platform" when building AMI images.
# -I platform=.../ami-platform.nix

{config, lib, pkgs, ...}:

with lib;

let
  nixPath = config.nix.nixPath;
  defaultNixPathStr = if nixPath == []
    then ""
    else builtins.foldl' (x: y: "${x}:${y}") (builtins.head nixPath) (builtins.tail nixPath);
in
{
  imports = [ <nixpkgs/nixos/modules/virtualisation/amazon-image.nix> ];

  options.customNixPathStr = mkOption {
    description = "Nix path string used for reconfiguration by the custom-init service";
    default = defaultNixPathStr;
  };

  config = {
    ec2.hvm = true;

    # Rerun configuration at init to include new user-data
    systemd.services.amazon-init.enable = false;
    systemd.services.custom_init = {
      script = ''
        #!${pkgs.stdenv.shell} -eu

        echo "Reruning nixos-rebuild with new user-data"
        userData=/etc/ec2-metadata/user-data
        if [ -s "$userData" ]; then
          echo "nixpath: ${config.customNixPathStr}"
          export NIX_PATH="${config.customNixPathStr}"
          export PATH=${pkgs.lib.makeBinPath [config.system.build.nixos-rebuild]}:$PATH
          export HOME=/root

          nixos-rebuild switch
        else
          echo "User data not available"
        fi
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
  };
}
