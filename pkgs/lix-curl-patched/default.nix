# this is a temporary package to build Lix with curl that has a patch for an annoying bug
# https://github.com/NixOS/nixpkgs/pull/460190
let
  pkgs' =
    import
      (fetchTarball "https://github.com/NixOS/nixpkgs/archive/804bca8429aaf887cc053266361dfe7498b02b0c.tar.gz")
      { };
in
pkgs'.lixPackageSets.stable.lix
