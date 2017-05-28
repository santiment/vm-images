{pkgs? (import <nixpkgs> {})}:

with pkgs;
rec {
  #pkgs = pkgs // {inherit yarn;};
  yarn = callPackage ./yarn {};
  yarn2nix = (callPackage ./yarn2nix { pkgs = pkgs // { inherit yarn;};});
  trollbox-client = (callPackage ./trollbox-client {inherit yarn2nix;}).trollboxClient;
  elasticsearch5 = callPackage ./elasticsearch {};
}
