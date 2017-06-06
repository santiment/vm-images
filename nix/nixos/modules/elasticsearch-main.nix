{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.elasticsearch-main;

  esConfig = ''
    network.host: ${cfg.listenAddress}
    http.port: ${toString cfg.port}
    transport.tcp.port: ${toString cfg.tcp_port}
    cluster.name: ${cfg.cluster_name}
    bootstrap.memory_lock: true
    ${cfg.extraConf}
  '';

  jvmConfig = ''
    ## JVM configuration

    ################################################################
    ## IMPORTANT: JVM heap size
    ################################################################
    ##
    ## You should always set the min and max JVM heap
    ## size to the same value. For example, to set
    ## the heap to 4 GB, set:
    ##
    ## -Xms4g
    ## -Xmx4g
    ##
    ## See https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html
    ## for more information
    ##
    ################################################################

    # Xms represents the initial size of total heap space
    # Xmx represents the maximum size of total heap space

    # These options will be set at runtime
    # -Xms2g
    # -Xmx2g

    ################################################################
    ## Expert settings
    ################################################################
    ##
    ## All settings below this section are considered
    ## expert settings. Don't tamper with them unless
    ## you understand what you are doing
    ##
    ################################################################

    ## GC configuration
    -XX:+UseConcMarkSweepGC
    -XX:CMSInitiatingOccupancyFraction=75
    -XX:+UseCMSInitiatingOccupancyOnly

    ## optimizations

    # disable calls to System#gc
    -XX:+DisableExplicitGC

    # pre-touch memory pages used by the JVM during initialization
    -XX:+AlwaysPreTouch

    ## basic

    # force the server VM (remove on 32-bit client JVMs)
    -server

    # explicitly set the stack size (reduce to 320k on 32-bit client JVMs)
    -Xss1m

    # set to headless, just in case
    -Djava.awt.headless=true

    # ensure UTF-8 encoding by default (e.g. filenames)
    -Dfile.encoding=UTF-8

    # use our provided JNA always versus the system one
    -Djna.nosys=true

    # use old-style file permissions on JDK9
    -Djdk.io.permissionsUseCanonicalPath=true

    # flags to configure Netty
    -Dio.netty.noUnsafe=true
    -Dio.netty.noKeySetOptimization=true
    -Dio.netty.recycler.maxCapacityPerThread=0

    # log4j 2
    -Dlog4j.shutdownHookEnabled=false
    -Dlog4j2.disable.jmx=true
    -Dlog4j.skipJansi=true

    ## heap dumps

    # generate a heap dump when an allocation from the Java heap fails
    # heap dumps are created in the working directory of the JVM
    -XX:+HeapDumpOnOutOfMemoryError

    # specify an alternative path for heap dumps
    # ensure the directory exists and has sufficient space
    #-XX:HeapDumpPath=\$\{heap.dump.path}

    ## GC logging

    #-XX:+PrintGCDetails
    #-XX:+PrintGCTimeStamps
    #-XX:+PrintGCDateStamps
    #-XX:+PrintClassHistogram
    #-XX:+PrintTenuringDistribution
    #-XX:+PrintGCApplicationStoppedTime

    # log GC status to a file with time stamps
    # ensure the directory exists
    #-Xloggc:\$\{loggc}

    # By default, the GC log file will not rotate.
    # By uncommenting the lines below, the GC log file
    # will be rotated every 128MB at most 32 times.
    #-XX:+UseGCLogFileRotation
    #-XX:NumberOfGCLogFiles=32
    #-XX:GCLogFileSize=128M

    # Elasticsearch 5.0.0 will throw an exception on unquoted field names in JSON.
    # If documents were already indexed with unquoted fields in a previous version
    # of Elasticsearch, some operations may throw errors.
    #
    # WARNING: This option will be removed in Elasticsearch 6.0.0 and is provided
    # only for migration purposes.
    #-Delasticsearch.json.allow_unquoted_field_names=true
    -Djava.security.policy=${cfg.dataDir}/security

  '';

  securityConfig = ''
    grant {
      permission java.io.FilePermission "${cfg.dataDir}/plugins/discovery-ec2/*", "read";
      permission java.io.FilePermission "${cfg.dataDir}/plugins/discovery-ec2", "read";
      permission javax.management.MBeanServerPermission "createMBeanServer";
      permission javax.management.MBeanServerPermission "findMBeanServer";
      permission javax.management.MBeanPermission "com.amazonaws.metrics.*", "*";
      permission javax.management.MBeanTrustPermission "register";
    };
  '';

  configDir = pkgs.buildEnv {
    name = "elasticsearch-config";
    paths = [
      (pkgs.writeTextDir "elasticsearch.yml" esConfig)
      (pkgs.writeTextDir "log4j2.properties" cfg.logging)
      (pkgs.writeTextDir "jvm.options" jvmConfig)
      (pkgs.writeTextFile {
        name = "elascticsearch-config-scripts";
        destination = "/scripts/.empty";
        text = "";
        })
    ];
  };

  esPlugins = pkgs.buildEnv {
    name = "elasticsearch-plugins";
    paths = cfg.plugins;
  };

  custom = import <custom> {};

  defaultES = custom.elasticsearch;
  discovery-ec2 = custom.elasticsearch5Plugins.discovery-ec2;

in {

  ###### interface

  options.services.elasticsearch-main = {
    enable = mkOption {
      description = "Whether to enable elasticsearch main server.";
      default = false;
      type = types.bool;
    };

    package = mkOption {
      description = "Elasticsearch package to use.";
      default = defaultES;
      defaultText = "pkgs.elasticsearch5";
      type = types.package;
    };

    listenAddress = mkOption {
      description = "Elasticsearch listen address.";
      default = "127.0.0.1";
      type = types.str;
    };

    port = mkOption {
      description = "Elasticsearch port to listen for HTTP traffic.";
      default = 9200;
      type = types.int;
    };

    tcp_port = mkOption {
      description = "Elasticsearch port for the node to node communication.";
      default = 9300;
      type = types.int;
    };

    cluster_name = mkOption {
      description = "Elasticsearch name that identifies your cluster for auto-discovery.";
      default = "elasticsearch-main";
      type = types.str;
    };

    extraConf = mkOption {
      description = "Extra configuration for elasticsearch.";
      default = "";
      type = types.str;
      example = ''
        node.name: "elasticsearch"
        node.master: true
        node.data: false
      '';
    };

    logging = mkOption {
      description = "Elasticsearch logging configuration.";
      default = ''
        status = error

        # log action execution errors for easier debugging
        logger.action.name = org.elasticsearch.action
        logger.action.level = debug

        appender.console.type = Console
        appender.console.name = console
        appender.console.layout.type = PatternLayout
        appender.console.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] %marker%m%n

        appender.rolling.type = RollingFile
        appender.rolling.name = rolling
        appender.rolling.fileName = ''${sys:es.logs.base_path}''${sys:file.separator}''${sys:es.logs.cluster_name}.log
        appender.rolling.layout.type = PatternLayout
        appender.rolling.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] %marker%.-10000m%n
        appender.rolling.filePattern = ''${sys:es.logs.base_path}''${sys:file.separator}''${sys:es.logs.cluster_name}-%d{yyyy-MM-dd}.log
        appender.rolling.policies.type = Policies
        appender.rolling.policies.time.type = TimeBasedTriggeringPolicy
        appender.rolling.policies.time.interval = 1
        appender.rolling.policies.time.modulate = true

        rootLogger.level = info
        rootLogger.appenderRef.console.ref = console
        rootLogger.appenderRef.rolling.ref = rolling

        appender.deprecation_rolling.type = RollingFile
        appender.deprecation_rolling.name = deprecation_rolling
        appender.deprecation_rolling.fileName = ''${sys:es.logs.base_path}''${sys:file.separator}''${sys:es.logs.cluster_name}_deprecation.log
        appender.deprecation_rolling.layout.type = PatternLayout
        appender.deprecation_rolling.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] %marker%.-10000m%n
        appender.deprecation_rolling.filePattern = ''${sys:es.logs.base_path}''${sys:file.separator}''${sys:es.logs.cluster_name}_deprecation-%i.log.gz
        appender.deprecation_rolling.policies.type = Policies
        appender.deprecation_rolling.policies.size.type = SizeBasedTriggeringPolicy
        appender.deprecation_rolling.policies.size.size = 1GB
        appender.deprecation_rolling.strategy.type = DefaultRolloverStrategy
        appender.deprecation_rolling.strategy.max = 4

        logger.deprecation.name = org.elasticsearch.deprecation
        logger.deprecation.level = warn
        logger.deprecation.appenderRef.deprecation_rolling.ref = deprecation_rolling
        logger.deprecation.additivity = false

        appender.index_search_slowlog_rolling.type = RollingFile
        appender.index_search_slowlog_rolling.name = index_search_slowlog_rolling
        appender.index_search_slowlog_rolling.fileName = ''${sys:es.logs.base_path}''${sys:file.separator}''${sys:es.logs.cluster_name}_index_search_slowlog.log
        appender.index_search_slowlog_rolling.layout.type = PatternLayout
        appender.index_search_slowlog_rolling.layout.pattern = [%d{ISO8601}][%-5p][%-25c] %marker%.-10000m%n
        appender.index_search_slowlog_rolling.filePattern = ''${sys:es.logs.base_path}''${sys:file.separator}''${sys:es.logs.cluster_name}_index_search_slowlog-%d{yyyy-MM-dd}.log
        appender.index_search_slowlog_rolling.policies.type = Policies
        appender.index_search_slowlog_rolling.policies.time.type = TimeBasedTriggeringPolicy
        appender.index_search_slowlog_rolling.policies.time.interval = 1
        appender.index_search_slowlog_rolling.policies.time.modulate = true

        logger.index_search_slowlog_rolling.name = index.search.slowlog
        logger.index_search_slowlog_rolling.level = trace
        logger.index_search_slowlog_rolling.appenderRef.index_search_slowlog_rolling.ref = index_search_slowlog_rolling
        logger.index_search_slowlog_rolling.additivity = false

        appender.index_indexing_slowlog_rolling.type = RollingFile
        appender.index_indexing_slowlog_rolling.name = index_indexing_slowlog_rolling
        appender.index_indexing_slowlog_rolling.fileName = ''${sys:es.logs.base_path}''${sys:file.separator}''${sys:es.logs.cluster_name}_index_indexing_slowlog.log
        appender.index_indexing_slowlog_rolling.layout.type = PatternLayout
        appender.index_indexing_slowlog_rolling.layout.pattern = [%d{ISO8601}][%-5p][%-25c] %marker%.-10000m%n
        appender.index_indexing_slowlog_rolling.filePattern = ''${sys:es.logs.base_path}''${sys:file.separator}''${sys:es.logs.cluster_name}_index_indexing_slowlog-%d{yyyy-MM-dd}.log
        appender.index_indexing_slowlog_rolling.policies.type = Policies
        appender.index_indexing_slowlog_rolling.policies.time.type = TimeBasedTriggeringPolicy
        appender.index_indexing_slowlog_rolling.policies.time.interval = 1
        appender.index_indexing_slowlog_rolling.policies.time.modulate = true

        logger.index_indexing_slowlog.name = index.indexing.slowlog.index
        logger.index_indexing_slowlog.level = trace
        logger.index_indexing_slowlog.appenderRef.index_indexing_slowlog_rolling.ref = index_indexing_slowlog_rolling
        logger.index_indexing_slowlog.additivity = false
      '';
      type = types.str;
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/elasticsearch";
      description = ''
        Data directory for elasticsearch.
      '';
    };

    extraCmdLineOptions = mkOption {
      description = "Extra command line options for the elasticsearch launcher.";
      default = [];
      type = types.listOf types.str;
      example = [ "-Ejava.net.preferIPv4Stack=true" ];
    };

    plugins = mkOption {
      description = "Extra elasticsearch plugins";
      default = [];
      type = types.listOf types.package;
    };

    useEnvironmentFile = mkOption {
      description = "Pass configuration environment variables via a file at runtime";
      default = false;
      type = types.bool;
    };

    environmentFilePath = mkOption {
      description = "Path to environment file to be read at runtime";
      default = "-/nofile";
      type = types.string;
    };

    javaOptions = mkOption {
      description = "Java options passed at runtime";
      example = "-Xms2g -Xmx2g";
      default = "-Xms500m -Xmx500m";
      type = types.string;
    };

  };

  ###### implementation

  config = mkIf cfg.enable {

    # Set virtual memory
    boot.kernel.sysctl."vm.max_map_count" = 262144;

    systemd.services.elasticsearch = {
      description = "Elasticsearch Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "local-fs.target" "remote-fs.target"];
      path = [ pkgs.inetutils ];
      environment = {
        ES_HOME = cfg.dataDir;
        ES_JVM_OPTIONS = "${configDir}/jvm.options";

          #Default Java heap size. Can be overriden by setting ES_JAVA_OPTS in the user-data file
        ES_JAVA_OPTS = cfg.javaOptions;
      };
      serviceConfig = {
        EnvironmentFile = mkIf cfg.useEnvironmentFile cfg.environmentFilePath;
        ExecStart = "${cfg.package}/bin/elasticsearch -Epath.conf=${configDir} -Epath.logs=${cfg.dataDir}/logs ${toString cfg.extraCmdLineOptions}";
        User = "elasticsearch";
        PermissionsStartOnly = true;

        # Equivalent to ulimit -n 65536
        LimitNOFILE = 65536;

        # Number of threads we can start
        LimitNPROC = 2048;

        # Must be changed when bootstrap.mlockall: true
        LimitMEMLOCK = "infinity";

        # Disable timeout logic and wait until process is started and stopped
        TimeoutSec = "infinity";

        # SIGTERM signal is used to stop the Java process
        KillSignal = "SIGTERM";

        # Java process is never killed
        SendSIGKILL = "no";

        # When a JVM receives a SIGTERM signal it exits with code 143
        SuccessExitStatus = "143";

        Restart="always";
        RestartSec=10;                       # Restart service after 10 seconds if node service crashes

      };

      preStart = ''
        mkdir -m 0700 -p ${cfg.dataDir}
        echo '${securityConfig}' >${cfg.dataDir}/security

        # Install plugins
        # mkdir -p ${cfg.dataDir}/plugins
        ln -sfT ${esPlugins} ${cfg.dataDir}/plugins
        ln -sfT ${cfg.package}/lib ${cfg.dataDir}/lib
        ln -sfT ${cfg.package}/modules ${cfg.dataDir}/modules
        if [ "$(id -u)" = 0 ]; then chown -R elasticsearch ${cfg.dataDir}; fi
      '';
      # postStart = mkBefore ''
      #   until ${pkgs.curl.bin}/bin/curl -s -o /dev/null ${cfg.listenAddress}:${toString cfg.port}; do
      #     sleep 1
      #   done
      # '';
    };

    #environment.systemPackages = [ cfg.package ];

    # Enable ports on firewall
    networking.firewall.allowedTCPPorts = [ cfg.port cfg.tcp_port ];

    users = {
      groups.elasticsearch.gid = config.ids.gids.elasticsearch;
      users.elasticsearch = {
        uid = config.ids.uids.elasticsearch;
        description = "Elasticsearch daemon user";
        home = cfg.dataDir;
        group = "elasticsearch";
      };
    };
  };
}
