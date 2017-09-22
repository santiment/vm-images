{config, lib, pkgs, ...}:

with lib;

let cfg = config.services.santiment.consul;

in
{
   options.services.santiment.consul = {

     enable = mkOption {
       description = "Whether to enable the consul service";
       default = false;
       type = types.bool;
     };

     enableServer = mkOption {
       description = "Whether to enable the consul server service";
       default = false;
       type = types.bool;
     };

     environment = mkOption {
       description = "Deployment environment. Used for consul aws discovery";
       type = types.string;
       default = "stage";
     };

     bootstrapExpect = mkOption {
       description = "Expected number of consul servers";
       type = types.int;
       default = 1;
     };

     ui = mkOption {
       description = "Whether to enable the Consul UI";
       type = types.bool;
       default = false;
     };

     extraConfigFiles = mkOption {
       description = ''
         Extra configuration files to pass to consul
	 NOTE: These will not trigger the service to be  restarted when altered.
       '';

       default = [];
       type = types.listOf types.str;
       
     };

     
   };

   config = mkIf (cfg.enable or cfg.enableServer) {

     # Start the consul service
     services.consul = {
       enable = true;
       package = (import <custom> {}).consul;

       interface = {
         advertise = "eth0";
       };

       extraConfig = {
         server = cfg.enableServer;
	 client_addr = "0.0.0.0";
	 bootstrap_expect = if cfg.enableServer then cfg.bootstrapExpect else null;
	 retry_join = ["provider=aws tag_key=Environment tag_value=${cfg.environment}"];
	 ui = cfg.ui;
       };

       extraConfigFiles = cfg.extraConfigFiles;
     };

     #Set up DNS
     services.dnsmasq = {
       enable = true;
       servers = ["/consul/127.0.0.1#8600"];
     };

     # Set up firewall

     # Agent ports
     networking.firewall.allowedTCPPorts = [ 8301 ]
       ++ (if cfg.enableServer then [8300 8302] else [])
       ++ (if cfg.ui then [ 8500 ] else []);

     networking.firewall.allowedUDPPorts = [ 8301 ]
       ++ (if cfg.enableServer then [8302] else []);
    
   };
   
}
