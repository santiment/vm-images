# Trollbox client machine.
{config, pkgs, ...}:
let
  userDataText = if (builtins.pathExists <user-data>)
    then builtins.readFile <user-data>
    else "";

  userData = if (userDataText == "")
    then {
      elasticsearchHost = "localhost";
      environment = "stage";
    }
    else builtins.fromJSON userDataText;
in
{
  #imports = [<platform> ../modules/trollbox-client.nix];
  imports = [<platform> ../modules/btce-client.nix ];

  #services.trollboxclient.enable = true;
  services.btce-client.enable = true;

  # the user-data file

  #services.trollboxclient.elasticsearchHost = "http://${userData.elasticsearchHost}";
  services.btce-client.elasticsearchHost = "http://${userData.elasticsearchHost}";
}
