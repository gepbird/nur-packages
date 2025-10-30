{
  pkgs,
  lib,
  fetchFromGitHub,
  pkgsCross,
  makeRustPlatform,
  pkg-config,
  makeWrapper,
  gtk3,
  libGL,
  openssl,
  atk,
  libxkbcommon,
  wayland,
}:

let
  rust-overlay = import ./rust-overlay (
    pkgs
    // {
      inherit (rust-overlay) rust-bin;
    }
  ) { };

  rustToolchain = rust-overlay.rust-bin.selectLatestNightlyWith (
    toolchain:
    toolchain.minimal.override {
    }
  );
  rustPlatform = makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };
in
rustPlatform.buildRustPackage rec {
  pname = "mint-mod-manager";
  version = "0.2.10-unstable-2025-05-04";

  src = fetchFromGitHub {
    owner = "trumank";
    repo = "mint";
    rev = "6335041f21b95976d29fe2cfbf282feb0c9f38ac";
    hash = "sha256-OyfLyAOMSrvXkyGL+PkyrZ7PLBgQ040SCv9Q85AkX+o=";
    deepClone = true;
    postFetch = ''
      echo -n $(git -C $out describe) > $out/GIT_VERSION
      rm -rf $out/.git
    '';
  };

  cargoHash = "sha256-E6pdDUrmmq8EhMFbfP7UTZ1+yysCCn7yc1/MO5jEVEw=";
}
