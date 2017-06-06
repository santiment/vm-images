# Bastion image

# This image is supposed to run in an autoscaling group for
# reliability. It supports having an elastic ip. The elastic ip id
# must be provided as an environment variable in the user_data script when running
# the image. This means the user data script should be of the following form:
# AWS_EIP_BASTION_ID=xxxxx
#

{config, pkgs, ...}:
let
  script =
  ''
    #!${pkgs.stdenv.shell} -eu

    echo "attempting to bind elastic ip $AWS_EIP_BASTION_ID to this instance..."

    export PATH=${pkgs.lib.makeBinPath [ pkgs.curl pkgs.gnugrep pkgs.gawk pkgs.awscli pkgs.coreutils]}:$PATH
    REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
    echo "REGION=$REGION"
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    echo "INSTANCE=$INSTANCE_ID"
    aws ec2 associate-address --region $REGION --instance-id $INSTANCE_ID --allocation-id $AWS_EIP_BASTION_ID
    echo "Finished"
  '';

in {
  imports = [<platform>];

  systemd.services.bastion-init = {
    inherit script;
    description = "Set the elastic ip";

    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    requires = [ "network-online.target" ];

    restartIfChanged = false;
    unitConfig.X-StopOnRemoval = false;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      EnvironmentFile = /etc/ec2-metadata/user-data;
    };
  };
}
