{ lib
, stdenv
, runCommandNoCC
, callPackage
, writeText
, writeTextDir
, buildNpmPackage
, fetchFromGitHub
, makeWrapper
, python3
, rsync
, nodejs
, typescript
, cmake
, coreutils
, binutils
}:
let
  utils = callPackage ./utils.nix {};

  /** Defines the configuration files. Within this attrset, each key will create a
      new properties file at "etc/config/<key>.nix.properties" */
  base-configs = {
    builtin = {
      sourcePath = "@dist@/examples";
    };
    execution = {
      cewrapper.config.sandbox = "etc/cewrapper/user-execution.json";
      cewrapper.config.execute = "etc/cewrapper/compilers-and-tools.json";
    };

    compiler-explorer = {
      compilerCacheConfig = "OnDisk(/tmp/compiler-explorer-cache,1024)";

      storageSolution = "local";
      localStorageFolder = "/tmp/compiler-explorer-storage/";

      python3 = "${python3.interpreter}";
      cmake = "${lib.getExe cmake}";
      ld = "${lib.getBin binutils}/bin/ld";
      readelf = "${lib.getBin binutils}/bin/readelf";
      mkfifo = "${lib.getBin coreutils}/bin/mkfifo";

      textBanner = "Compiler Explorer for Nix";
    };
  };
in
buildNpmPackage rec {

  pname = "compiler-explorer";
  version = "10723";

  src = fetchFromGitHub {
    owner = "compiler-explorer";
    repo = "compiler-explorer";
    rev = "gh-${version}";
    hash = "sha256-e8G1WNII61FWGscxSTlB2GvDP5e3945AslDP2h4jr2k=";
  };

  npmDepsHash = "sha256-8e8JtVeJXx1NxwYlN4SRJB2K/RJv9plnAwlRNWHWD1M=";

  nativeBuildInputs = [ ];

  CYPRESS_INSTALL_BINARY = 0;

  # see: https://github.com/compiler-explorer/compiler-explorer/blob/main/etc/scripts/build-dist.sh
  buildPhase = ''
    runHook preBuild

    npm run webpack
    npm run ts-compile

    runHook postBuild
  '';

  preInstall = ''
    export dist=$out/lib/node_modules/compiler-explorer

    cp -vR ./etc $etc
    cp -vR -L ${utils.makeConfigs base-configs}/. $etc/.

    for f in $etc/config/*.nix.properties; do
      substituteAllInPlace $f
    done

    rm -rf $etc/scripts/util/test
  '';

  postInstall = ''
    # trim file size, following upstream's build-dist.sh
    rm -rf $dist/node_modules/.cache/ $dist/node_modules/monaco-editor/
    find $dist/node_modules -name \*.ts -delete

    cp -rv out $dist

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/compiler-explorer \
      --set NODE_ENV production \
      --set-default COMPILER_EXPLORER_ETC $etc/etc/compiler-explorer \
      --add-flags $dist/out/dist/app.js \
      --add-flags --dist \
      --add-flags "--webpackContent $out/static" \
      --add-flags "--env nix" \
      --add-flags '--rootDir $COMPILER_EXPLORER_ETC'
  '';

  # out is for main program files. etc stores the default ./etc/ configuration files.
  outputs = [ "out" "etc" ];

  passthru.utils = utils;

  meta = with lib; {
    description = "Compiler Explorer is an interactive compiler exploration website. Edit code in C, C++, Rust, python, go and compile it in real time" ;
    homepage = "https://github.com/compiler-explorer/compiler-explorer";
    maintainers = with maintainers; [ rucadi ];
    platforms = platforms.all;
    license = licenses.bsd2;
    mainProgram = "compiler-explorer";
  };
}
