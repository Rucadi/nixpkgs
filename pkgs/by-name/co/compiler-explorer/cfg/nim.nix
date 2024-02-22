{ utils
, writeText
, defaultGcc
, nim
}:
let
 nimcfg =
    {
      compilers="nim";
      supportsBinary="true";
      compilerType="nim";
      objdumper="${defaultGcc}/bin/objdump";
      demangler="${defaultGcc}/bin/c++filt";
      binaryHideFuncRe=''^(__.*|_(init|start|fini)|(de)?register_tm_clones|call_gmon_start|frame_dummy|.plt.*|.*@plt|_dl_relocate_static_pie)$'';
      libs="";
      compiler.nim = {
        name="nim ${nim.version}";
        exe="${nim}/bin/nim";
      };
    };
in writeText "nim.defaults.properties" ''
    ${utils.attrToDot nimcfg }
  ''