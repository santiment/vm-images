{config, lib, pkgs, ...}:
with lib;
let
  cfg = config.services.trollboxclient;
  package = (import <custom> {}).trollbox-client;
in {

  options.services.trollboxclient = {

    enable = mkOption {
      description = "Whether to enable the trollbox client";
      default = false;
      type = types.bool;
    };

    elasticsearchHost = mkOption {
      description = "Elasticsearch host url";
      default = "http://localhost";
      type = types.string;
    };

    elasticsearchPort = mkOption {
      description = "Elasticsearch port";
      default = "9200";
      type = types.string;
    };

    elasticsearchAPIVersion = mkOption {
      description = "Version of the elasticsearch API";
      default = "5.3";
      type = types.string;
    };

    poloniexWebsocketUrl = mkOption {
      description = "Poloniex websocket URL";
      default = "wss://api2.poloniex.com:443";
      type = types.string;
    };

  };

  config = mkIf cfg.enable {
    systemd.services.trollboxclient = {
      description = "Trollbox client";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        TC_ELASTICSEARCH_API_VERSION = cfg.elasticsearchAPIVersion;
        TC_ELASTICSEARCH_PORT = cfg.elasticsearchPort;
        TC_POLONIEX_WEBSOCKET_URL = cfg.poloniexWebsocketUrl;
        TC_ELASTICSEARCH_HOST = cfg.elasticsearchHost;
        NODE_ENV="production";
      };

      serviceConfig = {
        ExecStart="${package}/bin/trollboxclient";
        Restart="always";
        RestartSec=10;                       # Restart service after 10 seconds if node service crashes
        StandardOutput="syslog";               # Output to syslog
        StandardError="syslog";                # Output to syslog
        SyslogIdentifier="trollboxclient";
        User="trollboxclient";
      };


    };

    users = {
      users.trollboxclient = {
        description = "Trollbox client deamon user";
        group = "trollboxclient";
      };
    };

  };
}
