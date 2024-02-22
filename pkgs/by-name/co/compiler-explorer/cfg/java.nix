{ utils
, writeText
, defaultGcc
, zulu17
}:
let


  javacfg = {
    compilers = "&java";
    group.java.compilers = "javadefault";
    compiler.javadefault.exe = "${zulu17}/bin/javac";
    compiler.javadefault.name = "zulu java ${zulu17.version}";
    compiler.javacdefault.runtime = "${zulu17}/bin/java";
    defaultCompiler = "javadefault";
    objdumper = "${zulu17}/bin/javap";
    instructionSet = "java";
    demangler = "";
    postProcess = "";
    options = "";
    supportsBinary = "false";
    needsMulti = "false";
    supportsExecute = "true";
    interpreted = "true";
  };

in
writeText "java.defaults.properties" ''
  ${utils.attrToDot javacfg }

''
