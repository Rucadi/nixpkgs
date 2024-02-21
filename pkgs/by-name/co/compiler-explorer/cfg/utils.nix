{lib, writeText, runCommand, python3}:
rec {
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


}