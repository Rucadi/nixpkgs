{ lib, stdenv, runCommand, writeText, buildNpmPackage, fetchFromGitHub, makeWrapper, python3, cypress
, nodejs_20
, husky
, typescript
, cmake
, coreutils
, gcc48, gcc49, gcc6, gcc7, gcc8, gcc9, gcc10, gcc11, gcc12, gcc13
, clang_9, clang_11, clang_12, clang_13, clang_14, clang_15, clang_16, clang_17
, lld_17, llvmPackages_17
}:
let

   utils = import ./cfg/utils.nix {inherit lib writeText runCommand python3;};
   defaultGcc = gcc13;
   defaultClang = clang_17;

   cppConfigFile = import ./cfg/cpp.nix {
    inherit writeText utils defaultGcc defaultClang gcc48 gcc49 gcc6 gcc7 gcc8 gcc9 gcc10 gcc11 gcc12 gcc13 clang_9
            clang_11 clang_12 clang_13 clang_14 clang_15 clang_16 clang_17 lld_17 llvmPackages_17;
     };
   ceConfigFile = import ./cfg/compilerExplorer.nix {
    inherit lib writeText utils defaultGcc python3 cmake coreutils;
   };
   executionConfigFile = import ./cfg/execution.nix {
        inherit writeText utils;
   };

    pname = "compiler-explorer";
    version = "10723";
    src = fetchFromGitHub {
        owner = "compiler-explorer";
        repo = "compiler-explorer";
        rev = "gh-${version}";
        hash = "sha256-e8G1WNII61FWGscxSTlB2GvDP5e3945AslDP2h4jr2k=";
    };
    NODE_DIR = "${nodejs_20}";
    nodeDeps = buildNpmPackage{
        inherit version src NODE_DIR;
        pname = "${pname}-node-deps";
        npmDepsHash = "sha256-8e8JtVeJXx1NxwYlN4SRJB2K/RJv9plnAwlRNWHWD1M=";
        nativeBuildInputs = [cypress nodejs_20 husky typescript];
        CYPRESS_INSTALL_BINARY = 0;
        dontNpmBuild = true;
        postPatch = "rm Makefile";
        buildPhase = "";
        installPhase = ''
        runHook preInstall

        mkdir -p $out/lib
        cp -r node_modules $out/lib

        runHook postInstall
        '';
    };

in
stdenv.mkDerivation  rec {
    inherit pname version src NODE_DIR executionConfigFile ceConfigFile cppConfigFile;
    postConfigure = ''
        cp -r ${nodeDeps}/lib/node_modules .
        cp etc/config/sponsors.yaml .
        cp etc/config/site-templates.conf .
        rm -rf etc/config/* 
        mv sponsors.yaml etc/config/
        mv site-templates.conf etc/config/
        cp ${ceConfigFile} etc/config/compiler-explorer.defaults.properties
        cp ${cppConfigFile} etc/config/c++.defaults.properties
        cp ${executionConfigFile} etc/config/execution.defaults.properties
    '';
    buildPhase = ''
        npm run webpack
        npm run ts-compile
    '';

    installPhase = ''
        mkdir -p $out
        cp -R * $out
        makeWrapper ${nodejs_20}/bin/node $out/bin/compiler-explorer \
                    --chdir $out \
                    --add-flags ./out/dist/app.js \
                    --add-flags "--webpackContent ./out/webpack/static" \
                    --set NODE_ENV production
    '';

  nativeBuildInputs = [
    nodejs_20 
    husky 
    typescript 
    makeWrapper 
    ];
  meta = with lib; {
    description = "HTTP, HTTP2, HTTPS, Websocket debugging proxy";
    homepage = "https://github.com/avwo/whistle";
    changelog = "https://github.com/avwo/whistle/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = [ maintainers.rucadi ];
    mainProgram = "whistle";
  };
  
}
