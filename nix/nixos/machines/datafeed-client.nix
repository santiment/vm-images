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
  imports = [<platform> ../modules/trollbox-client.nix];

  services.trollboxclient.enable = true;

    # Configure the trollbox client via environment variables passed in
  # the user-data file

  services.trollboxclient.elasticsearchHost = "http://${userData.elasticsearchHost}";
}
