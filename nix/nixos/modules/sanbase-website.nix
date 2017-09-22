{config, lib, pkgs, ...}:
with lib;
let
  cfg = config.services.santiment.sanbase-website;
  user = "www";
  group = "www";
  rootFolder = "/var/www";
  uid = 1666;
  gid = 1666;
  fcgiSocket = "/run/phpfpm/sanbase-nginx";

in
{

  imports = [ ./consul.nix ];
  
  options.services.santiment.sanbase-website = {
    enable = mkOption {
      description = "Whether to enable the sanbase website";
      default = false;
      type = types.bool;
    };

    environment = mkOption {
      description = "Deployment environment";
      default = "stage";
      type = types.string;
    };

  };

  config = mkIf cfg.enable {

    # Open HTTP(S) ports
    networking.firewall.allowedTCPPorts = [80 443];

    # Create the user who will run nginx and phpfpm
    users.extraUsers."${user}" = {
      isNormalUser = true;
      useDefaultShell = true;
      uid = uid;
      group = group;
      home = rootFolder;
      createHome = true;
    };

    users.extraGroups."${group}".gid = gid;

    # TODO: Set up consul and envconsul
    services.santiment.consul = {
      enable = true;
      environment = environment;
    };
    

    # Set up nginx
    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      user = user;
      group = group;

      virtualHosts."sanbase-low.santiment.net" = {
        root = "${rootFolder}/sanbase/";

	extraConfig = ''
	  rewrite ^/$ /cashflow permanent;
	'';

	locations."~ ^.+\.php(/|$)".extraConfig = ''
	  fastcgi_pass php_sanbase_fcgi;
	  fastcgi_split_path_info ^(.+\.php)(/.*)$;
	  include ${pkgs.nginx}/conf/fastcgi_params;
	  fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
	  fastcgi_param DOCUMENT_ROOT $document_root;
	  fastcgi_param QUERY_STRING $query_string;
	'';
       };

       appendHttpConfig = ''
         upstream php_sanbase_fcgi {
	   server unix:${fcgiSocket};
	 }
	  
       '';
    };

    # Set up PHP
    #TODO consul environment variables
    services.phpfpm.poolConfigs.sanbase-nginx = ''
      listen = ${fcgiSocket}
      listen.owner = ${user}
      listen.group = ${group}
      listen.mode = 0660
      user = ${user}
      pm = dynamic
      pm.max_children = 75
      pm.start_servers = 10
      pm.min_spare_servers = 5
      pm.max_spare_servers = 20
      pm.max_requests = 500
    '';

    # Set up auto deployment

    systemd.timers.sanbase-autodeploy = {
      description = "Sanbase autodeploy timer";

      wantedBy = ["multi-user.target"];
      after = [ "network.target" "local-fs.target" "remote-fs.target"];
      timerConfig = {
        OnBootSec = 60;
	OnUnitActiveSec = 300;
	Unit = "sanbase-autodeploy.service";
      };
    };

    systemd.services.sanbase-autodeploy = {
      description = "Sanbase autodeploy service";
      serviceConfig = {
        User = user;
	WorkingDirectory = rootFolder;
      };

      path = [ pkgs.git ];

      script = ''
        if [ ! -d "./sanbase" ]; then
	  git clone git@github.com:santiment/sanbase
	fi

	cd projecttransparency
	git checkout master
	git pull
      '';
    };

    # Run update scripts regularly
    systemd.timers.update-wallets = {
      description = "Update wallets timer";

      wantedBy = ["multi-user.target"];
      after = ["sanbase-autodeploy.service"];
      timerConfig = {
        OnBootSet = 60;
	OnUnitActiveSec = 900; # 15 minutes
	Unit = "update-wallets.service";
      };
    };

    systemd.services.update-wallets = {
      description = "Update wallets service";
      serviceConfig = {
        User = user;
	WorkingDirectory = "${rootFolder}/sanbase/scripts";
      };

      path = [ pkgs.php ];

      script = ''
        php update_wallets.php 
      ''; #TODO - consul
    };

    
    
    
  };

}
