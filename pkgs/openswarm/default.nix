{ lib
, buildNpmPackage
, fetchFromGitHub
, nodejs_22
}:

buildNpmPackage rec {
  pname = "@intrect/openswarm";
  version = "0.4.2";

  src = fetchFromGitHub {
    owner = "unohee";
    repo = "OpenSwarm";
    rev = "v${version}";
    hash = "sha256-7rrY3JFG3CyunIUx0JcyHesA12Nubso18+YAY6+5er4=";
  };

  npmDepsHash = "sha256-4vdZ+6I057XLtLuyy6nvdeKxkVi30fqH7VCETpKTHNg=";

  npmBuildScript = "build";
  npmRebuildFlags = [ "--ignore-scripts" ];

  # OpenSwarm ships a committed package-lock.json and builds with tsc.
  dontNpmInstall = false;

  nodejs = nodejs_22;

  meta = with lib; {
    description = "Autonomous AI agent orchestrator";
    homepage = "https://github.com/unohee/OpenSwarm";
    license = licenses.gpl3Only;
    mainProgram = "openswarm";
    platforms = platforms.linux;
  };
}
