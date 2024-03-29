{ lib
, stdenv
, fetchFromGitHub
, go
, scripthaus
, nodejs_21
, yarn
}:

stdenv.mkDerivation rec {
  pname = "waveterm";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "wavetermdev";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-5+m8zN2IIQydyKVG9YTe45nd8XQqrEpBLYIpnswTVfg=";
  };

  nativeBuildInputs = [ go scripthaus ];

  buildPhase = ''
    scripthaus run build-backend
  '';

  meta = with lib; {
    description = "Graphite cursor theme";
    homepage = "https://github.com/vinceliuice/Graphite-cursors";
    license = licenses.gpl3Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ oluceps ];
  };
}
