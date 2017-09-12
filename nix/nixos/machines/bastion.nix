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

  environment.systemPackages = [pkgs.postgresql];

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

  users.extraUsers = {

    jhildings = {
      description = "Johannes";
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxGxrTkbtjjxygJ70naz3TuqHu0j8yMm6NDyfTF2WesgLYFciGzGbQCspmte521i1l+AX11YXPXgsPPKSlO1Zc/nWUiPVHAf6GjQq1Hv2q9gs9ulFFcw/p+92wluDDBt2URtYg5+wZkLM/TyZC8PZmfrL6mVUixifZtnjYmxUwNxT2WdcmXCFmNLqcattou4igOnQzdjZXhYjZTekSs6MSPYBVoaLI0JO98h1FyPrCc2tAO8KgHoS7/y7gOCL28l9++dFuWBmFlFEtpQ+vFmqRCD55uJUzATHhdE5MUPP0kA3pnvjFboQzy9E6sZR/1Tzu+EsAd0cHG/EBacH8JMNt jhildings@ip-192-168-178-34.eu-central-1.compute.internal" ];
    };

    tzanko = {
      description = "Tzanko";
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCz2LY0Jj73tREjwzD+Cq1K4+Isfy3a2ctFzgcD369/slvODKTN13XhzSTFXHm6Huwc5USl62IqvOU5/Fq2u9lrQj+CiqYIg/96rupQBzsh/q1lbTIPnPa6BX+Wlnkb3DgcEr1E5Ripa8wh22C4gE3vhr59wGnnYaaSjVR5UsFKNhSGIiuWJ2j+5+rFivA6ek4AjysJITEEqtXmYgRkHZqoLk927QDFGTOm6wV/mqNfH4CZpphVM5iau6FcqTnCukY6EGEH6oec7K9P5olPqXGfzApez8dKP7FAEXAVqDkVb7aiPExsfiyvtoPCTK/MW3Z2BzIYXCZAGErP4tav6WA6Nc/YfF+7gWZSK+OIqFrmp6tAn9ledNvKKrt1fAycVsgUdwukhE5DhxWdf3TIXQVtbow1E8R24SIc5VEOmhdq0/48yl96ua/5AdAozCy9lIFFiRrZtljKJNkC80uL6ho7SzvSqkXdGGjGfzlc1wL2D83oElKFUwyVr6DP5e/qRXXNr07Qr+Uy3EuNvM1WFivj8oapfM5T4jVTh4OJvaCdDaXIVzKXayrCCqq7dF6cDnFI3ryXqcm40y78BFIeHAjPKNnrWTwbREKdSs5zswRiwFvqxXkI3xbRvHRH73s0rjQ1lRc4hNeEioAKzbYI5auwpADPJSHToB+zeLm1Y+ukfQ== tsanko@gmail.com" ];
    };

    bobrovova = {
      description = "Vladimir Bobrov";
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDiCPr/TyiQ0QqrLCefVaB0C46MvEUUvwh+fcKNa5LZmVZ9vfpSNyPfzAuh+3vpF0g3HnvOHeC4G5prWe4iVq1OM3IotTdC0xv48TXPYPvAyMz9zvMZ3OKxtglp+Qedr1pF8udZ663FgXHRFhT26Sh11t7gwTtpt22ESN5W+RoWvKlivOAJE5OW+smPk6pHhzhow1FkKiIcFSZ/Mqlsuj8dkLsSZDjkKXD84SkBQuR0b2J1Iz/ycA1JskP7xn3GVWFSqT4FDmnxVR5CwRVrujIj0jslY+gQYCIzg1u+lxcQanB2k7AEjJia7B+vHJIFdrdQEmKtVIwTQz9klsThDNyGVe2KOh6znShbIC2BmjctvW7HooHTidWxdR0eOg0cQh1tiZRrDMo8hD3UEYqYh/Hy8NeD4ohBUfwQas7l+Az+nlAIPZ3vTz8i5bxvA/Xvzcp59tIaU62BMy+Q86+z8CTudR+fqq+HStGJ6C1qnQ2N9lmXia923qnJFKNcU1RkFjcAFa5p2DYRhpSoWmy0bNVv+ZqS/2tFDyAONIyAZk2KwF93Hzat8jcttzSdycvLm7wtTO+L/sXb2MzrXi5YYW2+9UkL3pGH1UEwOVrKgDqGYzitBNg2K/Wsd68GfARaag4o12/NLOkALP2YlxJG4EG4Vdr1lvQWZbXZpJfaJMjrIw== bobrovova@gmail.com"];
    };

  }
}
