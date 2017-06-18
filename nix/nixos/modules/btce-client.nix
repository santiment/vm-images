{config, lib, pkgs, ...}:
with lib;
let
  cfg = config.services.btce-client;
  package = (import <custom> {}).btce-client;
in {

  options.services.btce-client = {

    enable = mkOption {
      description = "Whether to enable the btce client";
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

    useEnvironmentFile = mkOption {
      description = "Pass configuration environment variables via a file at runtime instead of via options";
      default = false;
      type = types.bool;
    };

    environmentFilePath = mkOption {
      description = "Path to environment file to be read at runtime";
      default = /nofile;
      type = types.path;
    };

  };

  config = mkIf cfg.enable {
    systemd.services.btce-client = {
      description = "BTCE client";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = mkIf (!cfg.useEnvironmentFile) {
        ELASTICSEARCH_PORT = cfg.elasticsearchPort;
        ELASTICSEARCH_HOST = cfg.elasticsearchHost;

        # By default python stdout and stderr are buffered which means
        # it doesn't log to journald in real time
        PYTHONUNBUFFERED = "True";
      };

      serviceConfig = {
        ExecStart="${package}/bin/collect-chat.py";
        Restart="always";
        RestartSec=10;                       # Restart service after 10 seconds if node service crashes
        StandardOutput="syslog";               # Output to syslog
        StandardError="syslog";                # Output to syslog
        SyslogIdentifier="btce-client";
        User="btce-client";
        EnvironmentFile = mkIf cfg.useEnvironmentFile cfg.environmentFilePath;
      };


    };

    users = {
      users.btce-client = {
        description = "BTCE client deamon user";
        group = "btce-client";
      };
    };

  };
}
