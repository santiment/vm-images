{pkgs? (import <nixpkgs> {})}:

with pkgs;
rec {
  #pkgs = pkgs // {inherit yarn;};
  yarn = callPackage ./yarn {};
  yarn2nix = (callPackage ./yarn2nix { pkgs = pkgs // { inherit yarn;};});
  trollbox-client = (callPackage ./trollbox-client {inherit yarn2nix;}).trollboxClient;
  elasticsearch = callPackage ./elasticsearch {};
  elasticsearchPlugins = callPackage ./elasticsearch/plugins.nix {inherit elasticsearch;};
  pythonPackages = callPackage ./python-packages.nix {pythonPackages = pkgs.python35Packages;};
  btce-client = callPackage ./btce-client {inherit pythonPackages;};
  consul = callPackage ./consul {};
}
