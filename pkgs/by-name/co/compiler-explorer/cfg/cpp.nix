{ utils
, writeText
, defaultGcc
, defaultClang
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
    gccVersions = [gcc48 gcc49 gcc6 gcc7 gcc8 gcc9 gcc10 gcc11 gcc12 gcc13];
    clangVersions = [clang_9 clang_11 clang_12 clang_13 clang_14 clang_15 clang_16 clang_17 ];

 cpp =
    {
        compilers="&gcc:&clang";
        group =
        {
            gcc = {
                compilers = utils.generateCompilerStrings gccVersions "gcc";
                compilerCategories = "gcc";
            };

            clang = {
                compilers= utils.generateCompilerStrings clangVersions "clang";
                intelAsm="-mllvm --x86-asm-syntax=intel";
                compilerType="clang";
                compilerCategories="clang";
            };
        };

        compiler =  (utils.generateCompilers gccVersions "g++" "gcc") // 
                    (utils.generateCompilers clangVersions "clang++" "clang");


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
in writeText "c++.defaults.properties" ''
    ${utils.attrToDot cpp }
    tools=clangquery:lld:readelf:nm:strings:llvmdwarfdumpdefault
  ''