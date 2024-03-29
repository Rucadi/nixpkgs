{ lib
, stdenv
, runCommand
, writeText
, buildNpmPackage
, fetchFromGitHub
, makeWrapper
, python3Full
, rsync
, nodejs_20
, typescript
, cmake
, coreutils
, gcc13
}:
let

  attrToDot =
    let
      attrToDotHelper = prefix: x:
        lib.concatStrings
          (lib.mapAttrsToList
            (k: v:
              if builtins.elem (builtins.typeOf v) [ "string" "int" "float" ]
              then "${prefix}${k}=${toString v}\n"
              else attrToDotHelper "${prefix}${k}." v)
            x);
    in
    attrToDotHelper "";

  execution = {
    sandboxType = "none";
    executionType = "none";
    cewrapper.config.sandbox = "etc/cewrapper/user-execution.json";
    cewrapper.config.execute = "etc/cewrapper/compilers-and-tools.json";
  };

  settings = {
      timeouts = {
        compileTimeoutMs = 20000;
        binaryExecTimeoutMs = 10000;
        compilationEnvTimeoutMs = 300000;
        compilationStaleAfterMs = 100000;
      };

      cache =
        {
          cacheConfig = "InMemory(50)";
          executableCacheConfig = "InMemory(50)";
          compilerCacheConfig = "OnDisk(/tmp/compiler-explorer-cache,1024)";
        };

      storage =
        {
          storageSolution = "local";
          localStorageFolder = "/tmp/compiler-explorer-storage/";
        };

      tools =
        {
          python3 = "${lib.getExe python3Full}";
          cmake = "${cmake}/bin/cmake";
          useninja = "false";
          ld = "${gcc13}/bin/ld";
          readElf = "${gcc13}/bin/readelf";
          mkfido = "${coreutils}/bin/mkfifo";
          headptrackPath = "";
          ldPath = "\${exePath}/../lib|\${exePath}/../lib32|\${exePath}/../lib64";
          demanglerType = "default";
          objdumperType = "default";
          cvCompilerCountMax = 15;
          ceToolsPath = "../compiler-explorer-tools";
        };

      misc =
        {
          defaultSource = "builtin";
          apiMaxAgeSecs = 600;
          maxConcurrentCompiles = 4;
          staticMaxAgeSecs = 1;
          maxUploadSize = "16mb";
          supportsExecute = "true";
          optionsAllowedRe = ".*";

          delayCleanup = "false";
          thirdPartyIntegrationEnabled = "true";
          statusTrackingEnabled = "false";
          showSponsors = "false";
          textBanner = "Compiler Explorer for NIX";
        };

      privacy = {
        cookiePolicyEnabled = "false";
        privacyPolicyEnabled = "false";
      };

      remote = {
        allowedShortUrlHostRe = "^([-a-z.]+\.)?(xania|godbolt)\.org$";
        googleShortLinkRewrite = "^https?://goo.gl/(.*)$|https://godbolt.org/g/$1";
        urlShortenService = "default";
        supportsLibraryCodeFilter = "false";
        remoteStorageServer = "https://godbolt.org";
      };
    };


ceConfigFile = writeText "compiler-explorer.defaults.properties" ''
  ${attrToDot settings.timeouts}
  ${attrToDot settings.cache}
  ${attrToDot settings.storage}
  ${attrToDot settings.tools}
  ${attrToDot settings.misc}
  ${attrToDot settings.privacy}
  ${attrToDot settings.remote}
'';

executionConfigFile = writeText "execution.defaults.properties" ''
  ${attrToDot execution}
'';

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

  nativeBuildInputs = [ nodejs_20 typescript rsync ];
  dontNpmBuild = true;
  dontNpmInstall = true;
  CYPRESS_INSTALL_BINARY = 0;
  NODE_DIR = "${nodejs_20}";
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
    cd ../..
    rsync -av out/dist/ $out/
    rsync -av out/webpack/static/ $out/static/
  '';


  installPhase = ''
    cd $out
    cp ${ceConfigFile} etc/config/compiler-explorer.defaults.properties
    cp ${executionConfigFile} etc/config/execution.defaults.properties

    makeWrapper ${nodejs_20}/bin/node bin/compiler-explorer \
        --chdir "$out" \
        --add-flags ./app.js \
        --add-flags "--webpackContent ./static" \
        --set NODE_ENV production
  '';

  meta = with lib; {
    description = "Compiler Explorer Is an interactive compiler exploration website. Edit code in C, C++, Rust, python, go and compile it in real time" ;
    homepage = "https://github.com/compiler-explorer/compiler-explorer";
    maintainers = with maintainers; [ rucadi ];
    platforms = platforms.all;
    license = licenses.bsd2;
    mainProgram = "compiler-explorer";
  };
}
