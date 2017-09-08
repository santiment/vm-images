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

  config = {
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
        else "-Xms1g -Xmx1g";
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

    networking.firewall.allowedTCPPorts = [ 8300 8301 8302 8400 8500 8600 ];
    networking.firewall.allowedUDPPorts = [ 8301 8302 8400 8500 8600 ];
    services.consul = {
      enable = true;
      package = (import <custom> {}).consul;

      interface = {
        advertise = "eth0";
      };
      

      extraConfig = {
        client_addr = "0.0.0.0";
        server = true;
        #The terraform user_data file sends a string so we have to convert it
        bootstrap_expect = if builtins.isInt userData.consulNumberOfServers
	  then userData.consulNumberOfServers
	  else
	    let
	      maybe_int = builtins.fromJSON userData.consulNumberOfServers;
 	    in if builtins.isInt maybe_int
	      then maybe_int
	      else throw "Could not convert userData value ${userData.consuleNumberOfServers} to int";
	    
	ui =  true;
	retry_join = ["provider=aws tag_key=Environment tag_value=${userData.environment}"];
      };
    };

  };


}
