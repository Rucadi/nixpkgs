{ lib
, flutter
, fetchFromGitHub
, makeDesktopItem
, pkg-config
, openjdk
, xdg-user-dirs
}: flutter.buildFlutterApplication rec {
  pubspecLock = lib.importJSON ./pubspec.lock.json;
  pname = "fehviwer";
  version = "1.5.4+534";
  vendorHash = "sha256-QqR1isHtQqGDhxkzuy5hm7Vem9iI1qBfK5GZLt/h03U=";
  gitHashes = 
  {
    archive_async = "sha256-pc4lb0NiGAN8a9y/5Ui67Z70Roo0aOgNeDHJMRQNgIQ=";
    flutter_android_volume_keydown = "sha256-TGDmstmY3x+Nvw6LZ1KAZgArG3IhQnM43exZ6O/bnx0=";
    flutter_boring_avatars = "sha256-MlTImFAThm3aiXy41SK846cNpi/YeHLWZLh39FDTaAs=";
    flutter_downloader = "sha256-ADjvQ1r+LpqNrBFxIBKW9NldVftWblEZWPpNYKL9hlE=";
    flutter_egg = "sha256-hfB8NRPZywFbP4lHtDG3SRn+4jVXZKZX68h4W2o8g2s=";
    google_translator = "sha256-fcEb/skxTaq8SsoJJB2m7oVuFjnh/C5knl3gP9PQgWk=";
    learning_language = "sha256-oiGTwPfscVB3eZeugXgU+wnUdsY68fMth+j7A6DI49o=";
    linkfy_text = "sha256-9vK2bjwboTf/ZwA2ZbEiKfbRsFDBTnjvZxnh4bTGVYc=";
    open_by_default = "sha256-e4GRjIe5Hw1GxxCNTv/xw1xlmGGeHMKEn1PZ2gysT/g=";
    receive_sharing_intent = "sha256-CRR5GUQ/wJtbGIIfEBUa+aycWLNtMcjqY12zHWMNrL8=";
    saf ="sha256-XKGxXHoDSQb/hGyqcAECIwJrxoNoS81hiYLfiKxA9CQ=";
    system_network_proxy = "sha256-DgXnqhJbD0YPSA+9aExYgu9saR8NNbRatc5lCLvaF7A=";
    window_size = "sha256-71PqQzf+qY23hTJvcm0Oye8tng3Asr42E2vfF1nBmVA=";
  };

  src = fetchFromGitHub {
    owner = "3003h";
    repo = "FEhViewer";
    rev = "v${version}";
    hash = "sha256-4sVKpmfrJRJJhWLAUDVE/hjKMYSJhi4h1a9arXPU+AI=";
  };

  nativeBuildInputs = [openjdk];
  runtimeInputs = [ xdg-user-dirs ];

  patches = [./linux_project.patch ./linux_feature.patch ./font.patch];

  prePatch = ''
    mv lib/config/config.dart.sample lib/config/config.dart 
  '';

  postInstall = ''
    rm -rf $out/bin/*
    makeWrapper $out/app/fehviewer $out/bin/fehviewer  \
            --prefix LD_LIBRARY_PATH : $out/app/lib \
            --prefix PATH : ${lib.makeBinPath [ xdg-user-dirs ]}
  '';


desktopItem = makeDesktopItem {
    name = "FEhViewer";
    exec = "@out@/bin/fehviewer";
    desktopName = "FEhViewer";
    genericName = "View E-Hentai and ExHentai libraries!";
    categories = [ "Adult" "Viewer" "Art" ];
  };

  meta = with lib; {
    description = "View E-Hentai and ExHentai libraries!";
    homepage = "https://github.com/3003h/FEhViewer";
    license =  "Apache 2.0";
    maintainers = with maintainers; [ rucadi ];
    platforms = platforms.linux;
  };
}