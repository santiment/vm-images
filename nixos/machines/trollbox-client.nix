# Trollbox client machine.
{config, pkgs, ...}:
let
  terraform = builtins.fromJSON (builtins.readFile <terraform>);
in {
  imports = [<platform> ../modules/trollbox-client.nix];

  services.trollboxclient.enable = true;
  services.trollboxclient.elasticsearchHost = "http://"+terraform.elasticsearch_elb_dns.value;
}
