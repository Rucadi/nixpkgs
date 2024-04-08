 { lib
, stdenv
, fetchYarnDeps
, fetchFromGitHub
, nodejs
, python3
, makeWrapper
, git
, docker
, fetchNpmDeps
, buildNpmPackage
, docker-compose
, npm-lockfile-fix
}:
 buildNpmPackage rec {
  pname = "cloudcmd";
  version = "17.3.3";

  src = fetchFromGitHub {
    owner = "coderaiser";
    repo = "cloudcmd";
    rev = "v${version}";
    hash = "sha256-iklTtHcmTtv53gJ5Bke4S1mbgtzftZa2XZ8ugDEIWWg=";
 };
  nativeBuildInputs = [makeWrapper];
  npmDepsHash = "sha256-xY0P0BOqk2cKds7aOOHKYw0GEPOwv3vXx1Uw9/xsbP8=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    chmod +w ./package-lock.json
  '';

  dontNpmBuild = true;

  # These build and install steps have been 
  # copied from the release Dockerfile of cloudcmd
  buildPhase = ''
    mkdir -p $out/usr/src/app
    cp -r $src/* $out/usr/src/app
    pushd $out/usr/src/app
    npm install --production
    popd
  '';

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper "${nodejs}/bin/node" "$out/bin/cloudcmd" \
      --add-flags "$out/usr/src/app/bin/cloudcmd.mjs"
  '';

  meta = with lib; {
    description = "A file manager with integrated terminal and a text editor for the web";
    homepage = "https://cloudcmd.io/";
    license = licenses.mit;
    maintainers = with maintainers; [ rucadi ];
    platforms = platforms.unix;
    mainProgram = "cloudcmd";
  };
}
