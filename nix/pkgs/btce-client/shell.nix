with import <nixpkgs> {};
(
  let
    custom = import <custom> {};
    elastic-py = custom.pythonPackages.elasticsearch;
  in python35.buildEnv.override rec {
    extraLibs = with custom.pythonPackages; [elasticsearch btceapi];
  }
).env
