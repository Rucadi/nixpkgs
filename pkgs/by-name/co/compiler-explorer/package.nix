{ lib, stdenv, runCommand, writeText, buildNpmPackage, fetchFromGitHub, makeWrapper, python3, cypress, nodejs_20, husky, typescript }:
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

    jsonToDot = x : builtins.readFile (runCommand "jsonToDot.dot" {} ''
                    echo '${builtins.toJSON x}' | ${python3}/bin/python ${pythonJsonToDot} > $out
                    '');
                    
in
stdenv.mkDerivation  rec {
    inherit pname version src NODE_DIR;
    postConfigure = ''
        cp -r ${nodeDeps}/lib/node_modules .

        sed -i -e 's|localStorageFolder=\./lib/storage/data|localStorageFolder=/tmp/compiler-explorer-storage|' etc/config/compiler-explorer.defaults.properties
        sed -i -e 's|compilerCacheConfig=OnDisk(out/compiler-cache,1024)|compilerCacheConfig=OnDisk(/tmp/compiler-explorer-cache,1024)|' etc/config/compiler-explorer.defaults.properties

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
                    --add-flags "--webpackContent $out/webpack/static" \
                    --set NODE_ENV production
    '';
  nativeBuildInputs = [nodejs_20 husky typescript makeWrapper];
  meta = with lib; {
    description = "HTTP, HTTP2, HTTPS, Websocket debugging proxy";
    homepage = "https://github.com/avwo/whistle";
    changelog = "https://github.com/avwo/whistle/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = [ maintainers.rucadi ];
    mainProgram = "whistle";
  };
}
