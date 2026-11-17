{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchNpmDeps,
  npmHooks,
  nodejs,
  pkg-config,
  dbus,
  wrapGAppsHook3,
  makeDesktopItem,
  copyDesktopItems,
  aws-lc,
  cacert,
  procps,
  webkitgtk_4_1,
  glib-networking,
  libayatana-appindicator,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "lumo-desktop";
  version = "0.5.9";

  src = fetchFromGitHub {
    owner = "ProtonLumo";
    repo = "lumo-desktop";
    rev = "bd5e2c608bac61f215d4a2094e26ef88cb7bc1e0";
    hash = "sha256-sOvwsJWwDZiBQlaKERQgPGZzbWNjxTCs63aYsqYS8O8=";
  };

  cargoRoot = "src-tauri";
  buildAndTestSubdir = "src-tauri";
  cargoHash = "sha256-jhTy4Uv7x8UG64ur9Y6j2WUYXtf1OfZ5UjnxaoU8GcM=";

  # Upstream defaults to its development instance unless release builds override it.
  env.LUMO_URL = "https://lumo.proton.me";

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = "sha256-GqCjpQWj7d342yqs+H+1ckIgnVMx9wNDeET0uwQP0pM=";
  };

  nativeBuildInputs = [
    nodejs
    npmHooks.npmConfigHook
    pkg-config
    wrapGAppsHook3
    copyDesktopItems
  ];

  buildInputs = [
    aws-lc
    dbus
    webkitgtk_4_1
    glib-networking
    libayatana-appindicator
  ];

  nativeCheckInputs = [ procps ];

  preCheck = ''
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
  '';

  # Updates are managed through Nix rather than Tauri's binary updater.
  patches = [ ./disable-updater.patch ];

  postPatch = ''
    substituteInPlace src-tauri/tauri.conf.json \
      --replace-fail '"endpoints": ["https://lumo.protondownload.com/desktop/{{target}}/latest.json"]' \
        '"endpoints": []'
  '';

  preBuild = ''
    npm run build:webview
  '';

  preFixup = ''
    gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libayatana-appindicator ]})
    gappsWrapperArgs+=(--set-default SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt)
    gappsWrapperArgs+=(--set-default NIX_SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt)
  '';

  postInstall = ''
    for size in 32 128; do
      install -Dm644 src-tauri/icons/''${size}x''${size}.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/lumo-desktop.png
    done
    install -Dm644 src-tauri/icons/128x128@2x.png \
      $out/share/icons/hicolor/256x256/apps/lumo-desktop.png
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "Lumo";
      desktopName = "Lumo";
      comment = "Your private AI assistant";
      exec = "lumo-desktop %u";
      icon = "lumo-desktop";
      categories = [ "Office" ];
      mimeTypes = [ "x-scheme-handler/proton-lumo" ];
      terminal = false;
    })
  ];

  meta = {
    description = "Desktop app for Lumo, Proton's private AI assistant";
    homepage = "https://github.com/ProtonLumo/lumo-desktop";
    changelog = "https://github.com/ProtonLumo/lumo-desktop/blob/${finalAttrs.src.rev}/changelog.md";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ gepbird ];
    mainProgram = "lumo-desktop";
    platforms = lib.platforms.linux;
  };
})
