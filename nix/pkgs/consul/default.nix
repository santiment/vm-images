{ stdenv, lib, unzip, fetchurl }:

stdenv.mkDerivation rec {
  name = "consul-${version}";
  version = "0.9.2";

  buildInputs = [unzip];

  src = fetchurl {
     url = "https://releases.hashicorp.com/consul/0.9.2/consul_0.9.2_linux_amd64.zip";
     sha256 = "0a2921fc7ca7e4702ef659996476310879e50aeeecb5a205adfdbe7bd8524013";
  };


  #The unpack result is a file. The standard builder assumes that it
  #is a directory and after unpacking it changes to that
  #directory. This line should prevent that behaviour

  sourceRoot = ".";

  outputs = [ "out" "bin" ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $bin/bin
    cp ./consul $bin/bin
    ln -s $bin/bin $out/bin
  '';

  meta = with stdenv.lib; {
    description = "Tool for service discovery, monitoring and configuration";
    homepage = https://www.consul.io/;
    platforms = platforms.linux ++ platforms.darwin;
    license = licenses.mpl20;
  };
}


