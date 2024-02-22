{ lib, stdenv, runCommand, writeText, buildNpmPackage, fetchFromGitHub, makeWrapper, python3Full, cypress, rsync
, nodejs_20
, husky
, typescript
, cmake
, coreutils
, gcc48, gcc49, gcc6, gcc7, gcc8, gcc9, gcc10, gcc11, gcc12, gcc13
, clang_9, clang_11, clang_12, clang_13, clang_14, clang_15, clang_16, clang_17
, lld_17, llvmPackages_17
, rustc, rustfilt
, gccgo13
, zig
, nim2
, zulu17
}:
let

   utils = import ./cfg/utils.nix {inherit lib writeText runCommand python3Full;};
   defaultGcc = gcc13;
   defaultClang = clang_17;

   cppConfigFile = import ./cfg/c-cpp.nix {
    inherit writeText utils defaultGcc defaultClang gcc48 gcc49 gcc6 gcc7 gcc8 gcc9 gcc10 gcc11 gcc12 gcc13 clang_9
            clang_11 clang_12 clang_13 clang_14 clang_15 clang_16 clang_17 lld_17 llvmPackages_17;
        isC = false;
     };
   cConfigFile = import ./cfg/c-cpp.nix {
    inherit writeText utils defaultGcc defaultClang gcc48 gcc49 gcc6 gcc7 gcc8 gcc9 gcc10 gcc11 gcc12 gcc13 clang_9
            clang_11 clang_12 clang_13 clang_14 clang_15 clang_16 clang_17 lld_17 llvmPackages_17;
            isC = true;
     };
   rustConfigFile = import ./cfg/rust.nix {
    inherit defaultGcc rustc rustfilt writeText utils;
   };

   goConfigFile = import ./cfg/go.nix {
    inherit defaultGcc gccgo13 writeText utils;
   };

    pythonConfigFile = import ./cfg/python3.nix {
    inherit defaultGcc python3Full writeText utils;
   };
      javaConfigFile = import ./cfg/java.nix {
    inherit defaultGcc zulu17 writeText utils;
   };

      zigConfigFile = import ./cfg/zig.nix {
    inherit defaultGcc zig writeText utils;
   };
   nimConfigFile = import ./cfg/nim.nix {
    inherit defaultGcc nim2 writeText utils;
   };

   ceConfigFile = import ./cfg/compiler-explorer.nix {
    inherit lib writeText utils python3Full defaultGcc cmake coreutils;
   };
   executionConfigFile = import ./cfg/compiler-explorer-execution.nix {
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
in
buildNpmPackage{
        inherit version src NODE_DIR;
        pname = "${pname}-node-deps";
        npmDepsHash = "sha256-8e8JtVeJXx1NxwYlN4SRJB2K/RJv9plnAwlRNWHWD1M=";
        nativeBuildInputs = [nodejs_20 typescript husky rsync];
        CYPRESS_INSTALL_BINARY = 0;
        dontNpmBuild = true;
        dontNpmInstall = true;
        postPatch = ''
              rm Makefile
              cp etc/config/sponsors.yaml .
              cp etc/config/site-templates.conf .
              rm -rf etc/config/* 
              mv sponsors.yaml etc/config/
              mv site-templates.conf etc/config/
        '';

        buildPhase = ''
        rm -rf out
        rm -rf lib/storage/data
        mkdir -p out/dist
        cp -R etc out/dist/   
        cp -R examples out/dist/   
        cp -R views out/dist/   
        cp -R types out/dist/   
        cp -R package.json out/dist/   
        cp -R package-lock.json  out/dist/   
       
        # Set up and build and webpack everything
        npm install --no-audit
        npm run webpack
        npm run ts-compile

        # Now install only the production dependencies in our output directory
        cd out/dist
        npm install --no-audit --ignore-scripts --production
        #rm -rf node_modules/.cache/ node_modules/monaco-editor/
        #find node_modules -name \*.ts -delete

        # Output some magic for GH to set the branch name and release name

        # Run to make sure we haven't just made something that won't work
        node --no-warnings=ExperimentalWarning --loader ts-node/esm ./app.js --version --dist

        echo      rsync -av out/webpack/static/ $out/static/
        echo         rsync -av out/dist/ $out/

        cd ../..
        rsync -av out/dist/ $out/
        rsync -av out/webpack/static/ $out/static/
         cd $out
         cp ${ceConfigFile} etc/config/compiler-explorer.defaults.properties
         cp ${executionConfigFile} etc/config/execution.defaults.properties
         cp ${cConfigFile} etc/config/c.defaults.properties
         cp ${cppConfigFile} etc/config/c++.defaults.properties
         cp ${rustConfigFile} etc/config/rust.defaults.properties
         cp ${pythonConfigFile} etc/config/python.defaults.properties
         cp ${goConfigFile} etc/config/go.defaults.properties
         cp ${javaConfigFile} etc/config/java.defaults.properties
         cp ${nimConfigFile} etc/config/nim.defaults.properties
         cp ${zigConfigFile} etc/config/zig.defaults.properties
         
         makeWrapper ${nodejs_20}/bin/node bin/compiler-explorer \
             --chdir "$out" \
             --add-flags ./app.js \
             --add-flags "--webpackContent ./static" \
             --set NODE_ENV production
        '';

}