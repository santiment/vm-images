# Elasticsearch master node.
{config, pkgs, ...}:
{
  imports = [<platform> ../modules/elasticsearch-main.nix];

  services.elasticsearch-main = {
    enable = true;

    extraConf = ''
      node.master: true
      node.data: true
    '';

    cluster_name = "main";
    listenAddress = "[ \"_site_\", \"_local_\"]";

    dataDir = "/var/lib/elasticsearch";

    useEnvironmentFile = true;
    environmentFilePath = "-/etc/ec2-metadata/user-data";
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
