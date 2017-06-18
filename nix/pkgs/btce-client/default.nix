{pythonPackages}:
with pythonPackages;
buildPythonPackage (rec {
    name = "btce-client-0.1.0";
    src = ./.;

    doCheck = false;

    propagatedBuildInputs = [ elasticsearch btceapi ];

    meta = {
        description = "BTCE trollbox feed client";
    };
  })
