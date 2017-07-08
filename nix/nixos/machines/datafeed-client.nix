# Trollbox client machine.
{config, pkgs, ...}:
let
  userDataText = if (builtins.pathExists <user-data>)
    then builtins.readFile <user-data>
    else "";

  defaultUserData = {
    elasticsearchHost = "localhost";
    environment = "dev";
  };

  userData = if (userDataText == "")
    then defaultUserData
    else defaultUserData // (builtins.fromJSON userDataText);
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
