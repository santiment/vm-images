{ pkgs,  stdenv, fetchurl, fetchFromGitHub, unzip, nettools, elasticsearch }:

with pkgs.lib;

let
  esPlugin = a@{
    pluginName,
    installPhase ? ''
      mkdir -p $TMP/eshome/plugins
      ln -s ${elasticsearch}/lib $TMP/eshome/lib
      ES_HOME=$TMP/eshome ${elasticsearch}/bin/elasticsearch-plugin install file://$src
      cp -a $TMP/eshome/plugins $out
    '',
    ...
  }:
    stdenv.mkDerivation (a // {
      inherit installPhase;
      unpackPhase = "true";
      buildInputs = [ unzip nettools];
    });
in {

  discovery-ec2 = esPlugin rec {
    name = "${pluginName}-${version}";
    pluginName = "discovery-ec2";
    version = "5.4.0";
    src = fetchurl {
      url = "https://artifacts.elastic.co/downloads/elasticsearch-plugins/${pluginName}/${name}.zip";
      sha256 = "1pwf8sw7klfb0dy2mkq4r7s57kx95dspzhwv8cdid1jmldyrm6np";
    };
  };
}
