{ utils
, writeText
, defaultGcc
, zig
}:
let
 zigcfg =
    {
      compilers="&zig";
      supportsBinary="true";
      compilerType="zig";
      objdumper="${defaultGcc}/bin/objdump";
      versionFlag="version";
      binaryHideFuncRe="^(_.*|call_gmon_start|(de)?register_tm_clones|frame_dummy|.*@plt.*)$";
      libs="";
      group.zig.compilers="zig";
      compiler.zig.exe="${zig}/bin/zig";
      compiler.zig.name="zig ${zig.version}";
    };
in writeText "zig.defaults.properties" ''
    ${utils.attrToDot zigcfg }
  ''