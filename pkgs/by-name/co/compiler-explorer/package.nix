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

    defaultGcc = gcc13;
    defaultClang = clang_17;
    gccVersions = [gcc48
                    gcc49
                    gcc6
                    gcc7
                    gcc8
                    gcc9
                    gcc10
                    gcc11
                    gcc12
                    gcc13];

    clangVersions = [
                clang_9
                clang_11
                clang_12
                clang_13
                clang_14
                clang_15
                clang_16
                clang_17
    ];


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
                    

    createCompilerAttribute = (compiler: command: compiler-name: {
        exe = "${compiler}/bin/${command}";
        name = "${compiler-name}-${compiler.version}";
    });
    
    generateCompilers = (compilers: command : compiler-name:
        lib.foldl' (attrs: compiler: attrs // { "${compiler-name}-${compiler.version}" = createCompilerAttribute compiler command compiler-name; }) {} compilers);

    generateCompilerStrings = (compilers: name : builtins.concatStringsSep ":" (map (pkg: "${name}-${pkg.version}") compilers));


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
            ld="${defaultGcc}/bin/ld";
            readElf="${defaultGcc}/bin/readelf";
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
        group =
        {
            gcc = {
                compilers = generateCompilerStrings gccVersions "gcc";
                compilerCategories = "gcc";
            };

            clang = {
                compilers=generateCompilerStrings clangVersions "clang";
                intelAsm="-mllvm --x86-asm-syntax=intel";
                compilerType="clang";
                compilerCategories="clang";
            };
        };

        compiler =  (generateCompilers gccVersions "g++" "gcc") // 
                    (generateCompilers clangVersions "clang++" "clang");


        tools = 
        {
            clangquery= 
            {
                exe="${defaultClang}/bin/clang-query";
                name="clang-query";
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
                exe="${defaultGcc}/bin/readelf";
                type="postcompilation";
                class="readelf-tool";
                exclude="djggp";
                stdinHint="disabled";
            };

          nm = 
            {
                name="nm";
                exe="${defaultGcc}/bin/nm";
                type="postcompilation";
                class="nm-tool";
                exclude="djggp";
                stdinHint="disabled";
            };
          strings = 
          {
                name="strings";
                exe="${defaultGcc}/bin/strings";
                type="postcompilation";
                class="strings-tool";
                exclude="djggp";
                stdinHint="disabled";
          };

          llvmdwarfdumpdefault = 
          {
            name="llvm-dwarfdump";
            exe="${llvmPackages_17.bintools-unwrapped}/bin/llvm-dwarfdump";
            type="postcompilation";
            class="llvm-dwarfdump-tool";
            stdinHint="disabled";
          };
        };

        
        defaultCompiler="gcc-${defaultGcc.version}";
        postProcess="";
        demangler="${defaultGcc}/bin/c++filt";
        demanglerType="cpp";
        objdumper="${defaultGcc}/bin/objdump";
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
