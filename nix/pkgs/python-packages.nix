{fetchurl, fetchgit, pythonPackages}:
with pythonPackages;
pythonPackages // {
  elasticsearch = buildPythonPackage (rec {
    name = "elasticsearch-5.4.0";
    src = fetchurl {
      url = "mirror://pypi/e/elasticsearch/${name}.tar.gz";
      sha256 = "11bfnlwkl7b8a24r1rn9imw7h757y9imnzvgzdh33rqgwa4ccm77";

      };

      doCheck = false;

      propagatedBuildInputs = [ urllib3 requests2 ];
      buildInputs = [nosexcover mock];

      meta = {
        description = "Official low-level client for Elasticsearch";
        homepage = https://github.com/elasticsearch/elasticsearch-py;
      };
  });

  btceapi = buildPythonPackage (rec {
    name = "btce-0.9";
    src = fetchgit {
      url = "https://github.com/CodeReclaimers/btce-api";
      rev = "19ee417084d699b74de1a75d734161025a020a3d";
      sha256 = "14inz02rvg4m7jfakbncnw3qcm32kxhrrg697xzgvig4gs8adhw9";
      fetchSubmodules = true;
    };
  });

}
