{yarn2nix}:
{
  trollboxClient = yarn2nix.buildYarnPackage {
    name = "trollbox-client";
    src = ./.;
    packageJson = ./package.json;
    yarnLock = ./yarn.lock;
  };
}
