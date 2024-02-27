{ lib
, fetchFromGitLab
, rustPlatform
, pkg-config
, openssl
}:
rustPlatform.buildRustPackage rec {
  pname = "surfer";
  version = "0.1.0";

  src = fetchFromGitLab {
    owner = "surfer-project";
    repo = "surfer";
    fetchSubmodules = true;
    rev = version;
    hash = "sha256-xlyYeWz2loiJYnqY6IzUsq9d4GsK/jWszLO5bF2qXqA=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "codespan-0.12.0" = "sha256-3F2006BR3hyhxcUTaQiOjzTEuRECKJKjIDyXonS/lrE=";
      "egui_skia-0.5.0" = "sha256-Qsb3C+iiUpXTWuOnKEiNKpK61dYpgcz92iDIgvONN9o=";
      "local-impl-0.1.0"  = "";
      "tracing-tree-0.2.0" = "sha256-/JNeAKjAXmKPh0et8958yS7joORDbid9dhFB0VUAhZc=";

    };
  };

  nativeBuildInputs = [ pkg-config rustPlatform.bindgenHook ];
  buildInputs = [ openssl ];

  meta = with lib; {
    homepage = "https://surfer-project.org/";
    description = "An Extensible and Snappy Waveform Viewer";
    license = licenses.eupl12;
    maintainers = with maintainers; [ rucadi ];
    platforms = platforms.unix;
  };
}