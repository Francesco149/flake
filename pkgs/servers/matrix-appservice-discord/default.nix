{ lib, mkYarnPackage, fetchFromGitHub, runCommand, makeWrapper, python3, nodejs }:

assert lib.versionAtLeast nodejs.version "12.0.0";

let
  nodeSources = runCommand "node-sources" {} ''
    tar --no-same-owner --no-same-permissions -xf ${nodejs.src}
    mv node-* $out
  '';

in mkYarnPackage rec {
  pname = "matrix-appservice-discord";

  # when updating, run `./generate.sh <git release tag>`
  # until a new release, we need this commit to fix metrics and few other things
  version = "1.0.0-git-2022-06-17";

  src = fetchFromGitHub {
    owner = "Half-Shot";
    repo = "matrix-appservice-discord";
    rev = "d4c0e00b3bbdacb1fac6f5e4df918b85dd85c713";
    sha256 = "191jk091z3nll5h61jk31fw0x5zk3gqd3s5yk4zjpgdj0k1ll0hd";
  };

  packageJSON = ./package.json;
  yarnNix = ./yarn-dependencies.nix;

  pkgConfig = {
    better-sqlite3 = {
      buildInputs = [ python3 ];
      postInstall = ''
        # build native sqlite bindings
        npm run build-release --offline --nodedir="${nodeSources}"
     '';
    };
  };

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    # compile TypeScript sources
    yarn --offline build
  '';

  doCheck = true;
  checkPhase = ''
    # the default 2000ms timeout is sometimes too short on our busy builders
    yarn --offline test --timeout 10000
  '';

  postInstall = ''
    OUT_JS_DIR="$out/${passthru.nodeAppDir}/build"

    # server wrapper
    makeWrapper '${nodejs}/bin/node' "$out/bin/${pname}" \
      --add-flags "$OUT_JS_DIR/src/discordas.js"

    # admin tools wrappers
    for toolPath in $OUT_JS_DIR/tools/*; do
      makeWrapper '${nodejs}/bin/node' "$out/bin/${pname}-$(basename $toolPath .js)" \
        --add-flags "$toolPath"
    done
  '';

  # don't generate the dist tarball
  doDist = false;

  passthru = {
    nodeAppDir = "libexec/${pname}/deps/${pname}";
  };

  meta = {
    description = "A bridge between Matrix and Discord";
    homepage = "https://github.com/Half-Shot/matrix-appservice-discord";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ pacien ];
    platforms = lib.platforms.linux;
  };
}
