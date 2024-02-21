{ lib, stdenv, runCommand, writeText, buildNpmPackage, fetchFromGitHub, makeWrapper, python3, cypress
, nodejs_20
, husky
, typescript
, cmake
, coreutils
, gcc48
, gcc49
, gcc6
, gcc7
, gcc8
, gcc9
, gcc10
, gcc11 
, gcc12
, gcc13
, clang_9
, clang_11
, clang_12
, clang_13
, clang_14
, clang_15
, clang_16
, clang_17
, lld_17
, llvmPackages_17
}:
let
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

    pythonJsonToDot = writeText "jstodot"  ''
    import sys
    import json
    def dot_notate(obj, target=None, prefix=""):
        if target is None:
            target = {}
        for key, value in obj.items():
            if isinstance(value, dict):
                dot_notate(value, target, prefix + key + ".")
            else:
                target[prefix + key] = value
        return '\n'.join([f"{key}={value}" for key, value in target.items()])
    try:
        print(dot_notate(json.loads(sys.stdin.read())))
    except json.JSONDecodeError as e:
        print(f'Error parsing JSON: {e}', file=sys.stderr)
    '';

    attrToDot = x : builtins.readFile (runCommand "jsonToDot.dot" {} ''
                    echo '${builtins.toJSON x}' | ${python3}/bin/python ${pythonJsonToDot} > $out
                    '');
                    

    settings = 
    {
        timeouts = {
            compileTimeoutMs=20000;
            binaryExecTimeoutMs=10000;
            compilationEnvTimeoutMs=300000;
            compilationStaleAfterMs=100000;
        };

        cache = 
        {
            cacheConfig="InMemory(50)";
            executableCacheConfig="InMemory(50)";
            compilerCacheConfig="OnDisk(/tmp/compiler-explorer-cache,1024)";
        };
        
        storage = 
        {
            storageSolution="local";
            localStorageFolder="/tmp/compiler-explorer-storage/";
        };


        tools =
        {
            python3="${lib.getExe python3}";
            cmake="${cmake}/bin/cmake";
            useninja="false";
            ld="${gcc13}/bin/ld";
            readElf="${gcc13}/bin/readelf";
            mkfido="${coreutils}/bin/mkfifo";
            headptrackPath="";
            ldPath="\${exePath}/../lib|\${exePath}/../lib32|\${exePath}/../lib64";
            demanglerType="default";
            objdumperType="default";
            cvCompilerCountMax=15;
            ceToolsPath="../compiler-explorer-tools";
        };

        misc = 
        {
            defaultSource="builtin";
            apiMaxAgeSecs=600;
            maxConcurrentCompiles=4;
            staticMaxAgeSecs=1;
            maxUploadSize="16mb";
            supportsExecute="true";
            optionsAllowedRe=".*";

            delayCleanup = "false";
            thirdPartyIntegrationEnabled="true";
            statusTrackingEnabled="false";
            showSponsors = "false";
            textBanner = "Compiler Explorer for NIX";
        };

        privacy = {
            cookiePolicyEnabled="false";
            privacyPolicyEnabled="false";
        };

        remote = {
            allowedShortUrlHostRe="^([-a-z.]+\.)?(xania|godbolt)\.org$";
            googleShortLinkRewrite="^https?://goo.gl/(.*)$|https://godbolt.org/g/$1";
            urlShortenService="default";
            supportsLibraryCodeFilter="false";
            remoteStorageServer="https://godbolt.org";
        };
    };
    

    cpp =
    {
        compilers="&gcc:&clang";
        group.gcc = {
                compilers = "gcc48:gcc49:gcc6:gcc7:gcc8:gcc9:gcc10:gcc11:gcc12:gcc13";
                compilerCategories = "gcc";
            };

        compiler = {
            gcc48 = {
                exe = "${gcc48}/bin/g++";
                name = "gcc48";
            };
            gcc49 = {
                exe = "${gcc49}/bin/g++";
                name = "gcc49";
            };
            gcc6 = {
                exe = "${gcc6}/bin/g++";
                name = "gcc6";
            };
            gcc7 = {
                exe = "${gcc7}/bin/g++";
                name = "gcc7";
            };
            gcc8 = {
                exe = "${gcc8}/bin/g++";
                name = "gcc8";
            };
            gcc9 = {
                exe = "${gcc9}/bin/g++";
                name = "gcc9";
            };
            gcc10 = {
                exe = "${gcc10}/bin/g++";
                name = "gcc10";
            };
            gcc11 = {
                exe = "${gcc11}/bin/g++";
                name = "gcc11";
            };
            gcc12 = {
                exe = "${gcc12}/bin/g++";
                name = "gcc12";
            };
            gcc13 = {
                exe = "${gcc13}/bin/g++";
                name = "gcc13";
            };
        };
        
        group.clang = {
            compilers="clang_9:clang_11:clang_12:clang_13:clang_14:clang_15:clang_16:clang_17";
            intelAsm="-mllvm --x86-asm-syntax=intel";
            compilerType="clang";
            compilerCategories="clang";
        };

        compiler = {
             clang_9 ={
                exe = "${clang_9}/bin/clang++";
                name = "clang_9";
             };
             clang_11 ={
                exe = "${clang_11}/bin/clang++";
                name = "clang_11";
             };
             clang_12 ={
                exe = "${clang_12}/bin/clang++";
                name = "clang_12";
             };
             clang_13 ={
                exe = "${clang_13}/bin/clang++";
                name = "clang_13";
             };
             clang_14 ={
                exe = "${clang_14}/bin/clang++";
                name = "clang_14";
             };
             clang_15 ={
                exe = "${clang_15}/bin/clang++";
                name = "clang_15";
             };
             clang_16 ={
                exe = "${clang_16}/bin/clang++";
                name = "clang_16";
             };
             clang_17 ={
                exe = "${clang_17}/bin/clang++";
                name = "clang_17";
             };
        };

        tools = 
        {
            clangquery= 
            {
                exe="${clang_17}/bin/clang-query";
                name="clang-query 17";
                type="independent";
                class="clang-query-tool";
                stdinHint="Query commands";
            };

            lld = {
                name="ldd";
                exe="${lld_17}/bin/lld_17";
                type="postcompilation";
                class="readelf-tool";
                exclude="djggp";
                stdinHint="disabled";
            };

            readelf = 
            {
                name="readelf";
                exe="${gcc13}/bin/readelf";
                type="postcompilation";
                class="readelf-tool";
                exclude="djggp";
                stdinHint="disabled";
            };

          nm = 
            {
                name="nm";
                exe="${gcc13}/bin/nm";
                type="postcompilation";
                class="nm-tool";
                exclude="djggp";
                stdinHint="disabled";
            };
          strings = 
          {
                name="strings";
                exe="${gcc13}/bin/strings";
                type="postcompilation";
                class="strings-tool";
                exclude="djggp";
                stdinHint="disabled";
          };

          llvmdwarfdumpdefault = 
          {
            exe="${llvmPackages_17.bintools-unwrapped}/bin/llvm-dwarfdump";
            name="llvm-dwarfdump";
            type="postcompilation";
            class="llvm-dwarfdump-tool";
            stdinHint="disabled";
          };
        };

        
        defaultCompiler="gcc13";
        postProcess="";
        demangler="${gcc13}/bin/c++filt";
        demanglerType="cpp";
        objdumper="${gcc13}/bin/objdump";
        options="";
        supportsBinary="true";
        supportsBinaryObject="true";
        binaryHideFuncRe="^(__.*|_(init|start|fini)|(de)?register_tm_clones|call_gmon_start|frame_dummy|\.plt.*|_dl_relocate_static_pie)$";
        needsMulti="false";
        stubRe=''\bmain\b'';
        stubText="int main(void){return 0;/*stub provided by Compiler Explorer*/}";
        supportsLibraryCodeFilter="true";

        libs="";

    };

    execution = {
        sandboxType="none";
        executionType="none";
        cewrapper.config.sandbox="etc/cewrapper/user-execution.json";
        cewrapper.config.execute="etc/cewrapper/compilers-and-tools.json";
    };
in
stdenv.mkDerivation  rec {
    inherit pname version src NODE_DIR;
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

  ceConfigFile = writeText "compiler-explorer.defaults.properties" ''
    ${attrToDot settings.timeouts}
    ${attrToDot settings.cache}
    ${attrToDot settings.storage}
    ${attrToDot settings.tools}
    ${attrToDot settings.misc}
    ${attrToDot settings.privacy}
    ${attrToDot settings.remote}
  '';

  cppConfigFile = writeText "c++.defaults.properties" ''
    ${attrToDot cpp }
    tools=clangquery:lld:readelf:nm:strings:llvmdwarfdumpdefault
  '';

  executionConfigFile = writeText "execution.defaults.properties" ''
    ${attrToDot execution}
  '';

  
}
