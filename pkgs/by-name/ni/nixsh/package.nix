{ lib, stdenvNoCC, fetchFromGitHub, gawk, jq, gnused, gnugrep, coreutils}:

stdenvNoCC.mkDerivation rec {
  pname = "nixsh";
  version = "0.0.1.1";

  src = fetchFromGitHub {
    owner = "rucadi";
    repo = "nixsh";
    rev = version;
    hash = "sha256-S3cReVwV/QElk6e08d3mgae/EWpJG/s71KYHjP35CQM=";
  };

  nativeBuildInputs = [ gawk jq gnused gnugrep coreutils];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp -r lib/* $out/bin
  '';

  meta = with lib; {
    description = "Run bash scripts using nix power and take control of your environment variables";
    homepage = "https://github.com/rucadi/nixsh";
    license = licenses.mit;
    maintainers = with maintainers; [ rucadi ];
  };
}
