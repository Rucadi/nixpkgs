{ lib
, stdenv
, runCommand
, makeWrapper
, python3Full
, rsync
, writeText
, compiler-explorer-base
, gcc48, gcc10, gcc13
, clang_9, clang_14, clang_17 
, lld_17
, llvmPackages_17
}:
let

  defaultGcc = gcc13;
  defaultClang = clang_17;

  gccEntries = [gcc48 gcc10 gcc13];
  clangEntries = [clang_9 clang_14 clang_17];

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
    in attrToDotHelper "";

  compilerEntry = (compilerPkg: compilerName: compilerBinary:
    rec {
      type = compilerName;
      version = "${compilerPkg.version}";
      entry = compilerBinary + "-" + compilerName + "-" + version;
      visibleName = compilerName + " " + version;
      compilerPath = "${compilerPkg}/bin/${compilerBinary}";
    }
  );

  mapCompilerToEntry = (compilerList: compilerName: compilerBinary:
    (map (compilerPkg: compilerEntry compilerPkg compilerName compilerBinary) compilerList)
  );


  ce_configuredCompilersListFromEntries = (entries: builtins.concatStringsSep ":" (map (entry: "${entry.entry}") entries));

  ce_configuredCompilerNameAndBinaryListFromEntries =
    prefix: lib.concatMapStrings
      (entry:
        attrToDot {
          ${prefix}.${entry.entry} = {
            exe = entry.compilerPath;
            name = entry.visibleName;
          };
        });



  perform_kind = (isC: gccVersions: clangVersions: 
    let
        gccCommand = if isC then "gcc" else "g++";
        clangCommand = if isC then "clang" else "clang++";
        compilerType = if isC then "c" else "c++";
        gccEntries = mapCompilerToEntry gccVersions "gcc" gccCommand;
        clangEntries = mapCompilerToEntry clangVersions "clang" clangCommand;
        c_cpp = {
        compilers = "&gcc:&clang";
        group =
          {
            gcc = {
              compilers = ce_configuredCompilersListFromEntries gccEntries;
              compilerCategories = "gcc";
            };
            clang = {
              compilers = ce_configuredCompilersListFromEntries clangEntries;
              intelAsm = "-mllvm --x86-asm-syntax=intel";
              compilerType = "clang";
              compilerCategories = "clang";
            };
          };

        tools =
          {
            clangquery =
              {
                exe = "${defaultClang}/bin/clang-query";
                name = "clang-query";
                type = "independent";
                class = "clang-query-tool";
                stdinHint = "Query commands";
              };

            lld = {
              name = "ldd";
              exe = "${lld_17}/bin/lld_17";
              type = "postcompilation";
              class = "readelf-tool";
              exclude = "djggp";
              stdinHint = "disabled";
            };

            readelf =
              {
                name = "readelf";
                exe = "${defaultGcc}/bin/readelf";
                type = "postcompilation";
                class = "readelf-tool";
                exclude = "djggp";
                stdinHint = "disabled";
              };

            nm =
              {
                name = "nm";
                exe = "${defaultGcc}/bin/nm";
                type = "postcompilation";
                class = "nm-tool";
                exclude = "djggp";
                stdinHint = "disabled";
              };
            strings =
              {
                name = "strings";
                exe = "${defaultGcc}/bin/strings";
                type = "postcompilation";
                class = "strings-tool";
                exclude = "djggp";
                stdinHint = "disabled";
              };

            llvmdwarfdumpdefault =
              {
                name = "llvm-dwarfdump";
                exe = "${llvmPackages_17.bintools-unwrapped}/bin/llvm-dwarfdump";
                type = "postcompilation";
                class = "llvm-dwarfdump-tool";
                stdinHint = "disabled";
              };
          };


        defaultCompiler = "${(compilerEntry defaultGcc "gcc" gccCommand).entry}";
        postProcess = "";
        demangler = "${defaultGcc}/bin/c++filt";
        demanglerType = "cpp";
        objdumper = "${defaultGcc}/bin/objdump";
        options = "";
        supportsBinary = "true";
        supportsBinaryObject = "true";
        binaryHideFuncRe = "^(__.*|_(init|start|fini)|(de)?register_tm_clones|call_gmon_start|frame_dummy|\.plt.*|_dl_relocate_static_pie)$";
        needsMulti = "false";
        stubRe = ''\bmain\b'';
        stubText = "int main(void){return 0;/*stub provided by Compiler Explorer*/}";
        supportsLibraryCodeFilter = "true";

        libs = "";

      };
    in 
    writeText "${compilerType}.defaults.properties" ''
        ${attrToDot c_cpp }
        ${ce_configuredCompilerNameAndBinaryListFromEntries "compiler" gccEntries}
        ${ce_configuredCompilerNameAndBinaryListFromEntries "compiler" clangEntries}
        tools=clangquery:lld:readelf:nm:strings:llvmdwarfdumpdefault
      ''
   );


   cConfig = perform_kind true gccEntries clangEntries;
   cppConfig = perform_kind false gccEntries clangEntries;


in
stdenv.mkDerivation {
  pname = "compiler-explorer-cpp";
  name = "Compiler Explorer GCC/CLANG";
  version = compiler-explorer-base.version;
  
  phases = [ "installPhase" ];

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p $out/etc/config
    mkdir -p $out/bin
    cp ${compiler-explorer-base}/etc/config/* $out/etc/config/
    cp ${cConfig} $out/etc/config/c.defaults.properties
    cp ${cppConfig} $out/etc/config/c++.defaults.properties
    makeWrapper ${compiler-explorer-base}/bin/compiler-explorer $out/bin/compiler-explorer-cpp --add-flags "--rootDir=$out/etc"
  '';

  meta = with lib; {
    description = "Compiler Explorer Is an interactive compiler exploration website. Edit code in C, C++, Rust, python, go and compile it in real time" ;
    homepage = "https://github.com/compiler-explorer/compiler-explorer";
    maintainers = with maintainers; [ rucadi ];
    platforms = platforms.all;
    license = licenses.bsd2;
    mainProgram = "compiler-explorer-cpp";
  };
}
