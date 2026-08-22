{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  pipewire,
  libpulseaudio,
  ffmpeg,
}:

let
  version = "1.3.7.478";

  # Spotify only ever serves the current build at these fixed, unversioned
  # URLs (see https://developer.spotify.com/documentation/soloist/tutorials/getting-started),
  # and upstream builds self-expire (exit code 10) 90 days after they were
  # produced. There is no tagged/versioned release to pin against, so the
  # hash below will need periodic refreshing via passthru.updateScript.
  sources = {
    x86_64-linux = {
      url = "https://soloist-builds.spotifycdn.com/soloist_release_x86_64.tar.gz";
      hash = "sha256-GSnAZnLKt6Ox4kZ2TsSOPGDzydh0YWYM0k41b3/ufgo=";
    };
    aarch64-linux = {
      url = "https://soloist-builds.spotifycdn.com/soloist_release_arm64.tar.gz";
      hash = "sha256-qAyCdeUJRVZl0VutlEvVRM72ZMSzruBj6AoCv1pCor4=";
    };
  };

  currentSource =
    sources.${stdenv.hostPlatform.system}
      or (throw "soloist: unsupported system '${stdenv.hostPlatform.system}' (Spotify only publishes x86_64-linux, aarch64-linux and armv7l-linux builds)");

  # `soloist` doesn't link these directly (see `patchelf --print-needed`);
  # it dlopen()s whichever of them is available at runtime to talk to the
  # local audio server / decode media, trying several sonames of each in
  # turn (seen via `strings`: libpipewire-0.3.so.0, libpulse.so.0,
  # libavcodec.so.{54,56,57,58,60,61}, libavformat.so.{54,56,57,58,60,61}).
  runtimeLibs = [
    pipewire
    libpulseaudio
    ffmpeg
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "soloist";
  inherit version;

  src = fetchzip {
    inherit (currentSource) url hash;
    stripRoot = false;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 soloist $out/bin/soloist
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/soloist \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Official headless Spotify Connect client for Linux (Spotify's Soloist SDK)";
    longDescription = ''
      Spotify Soloist turns a Linux machine (including single-board
      computers like a Raspberry Pi) into a Spotify Connect speaker: it
      advertises itself on the local network, and the official Spotify app
      can then transfer/control playback to it, with audio going out
      through PipeWire or PulseAudio.

      Starting it requires a device name and a developer API key generated
      from a Spotify Premium account, e.g.:

          soloist --device-name "Living Room" --api-key "$SOLOIST_API_KEY"

      Run `soloist --help` and `soloist ctl --help` for the full CLI,
      including the optional local WebSocket control API (`--ws`).

      Keep the API key private: per Spotify, it's tied to the account that
      generated it and must not be shared or committed to logs/history.

      Spotify's terms prohibit redistributing Soloist archives/binaries;
      this derivation only ever fetches them straight from Spotify's own
      CDN (soloist-builds.spotifycdn.com) at build time, and is marked
      `unfree` (rather than `unfreeRedistributable`) so this repo's CI never
      builds or mirrors it into the public Cachix cache.

      Upstream builds also self-expire 90 days after they're produced (the
      binary exits with code 10 once expired), so `version` and the fetched
      hash here need periodic refreshing regardless of any actual upstream
      changes.
    '';
    homepage = "https://developer.spotify.com/documentation/soloist";
    changelog = "https://developer.spotify.com/documentation/soloist";
    license = lib.licenses.unfree;
    mainProgram = "soloist";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
