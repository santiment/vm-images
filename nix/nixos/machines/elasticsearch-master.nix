# Elasticsearch master node.
{config, pkgs, ...}:
let
  userDataText = if (builtins.pathExists <user-data>)
    then builtins.readFile <user-data>
    else "";
  xxx = builtins.trace (builtins.stringLength userDataText) userDataText;

  userData = if (xxx == "")
    then {
      minimumMasterNodes = "1";
      securityGroups = "";
      region = "";
      environment = "stage";
    }
    else builtins.fromJSON xxx;

in
{
  imports = [<platform> ../modules/elasticsearch-main.nix];


  services.elasticsearch-main = {
    enable = true;

    extraConf = ''
      node.master: true
      node.data: true
      discovery:
        type: ec2
        zen.minimum_master_nodes: "${userData.minimumMasterNodes}"
        ec2:
          groups: "${userData.securityGroups}"
      cloud.aws:
        region: "${userData.region}"
    '';

    cluster_name = "main";
    listenAddress = "[ \"_site_\", \"_local_\"]";

    dataDir = "/var/lib/elasticsearch";

    javaOptions = if userData.environment == "stage"
      then "-Xms300m -Xmx300m"
      else "-Xms2g -Xmx2g";
    plugins = [(import <custom> {}).elasticsearchPlugins.discovery-ec2];
  };

  fileSystems = {
    # Resize root volume if needed
    "/".autoResize = true;

    # Put the database on a separate volume
    "/var/lib/elasticsearch" = {
       device = "/dev/xvdb";
       fsType = "ext4";
       label = "elasticsearch-data";
       autoFormat = true;
       autoResize = true;
    };
  };
}
