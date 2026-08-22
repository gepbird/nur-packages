#!/usr/bin/env nix-shell
#!nix-shell --pure --keep NIX_PATH -i bash -p bash cacert curl nix common-updater-scripts

set -euo pipefail

# Spotify serves Soloist as rolling, unversioned builds at fixed URLs (no
# tagged release to diff against), and builds self-expire 90 days after
# they're produced. So unlike nix-update-driven packages, this always
# re-fetches, re-hashes and re-pins to whatever Spotify is currently
# serving, regardless of whether anything "changed" upstream.

x86_64Url="https://soloist-builds.spotifycdn.com/soloist_release_x86_64.tar.gz"
aarch64Url="https://soloist-builds.spotifycdn.com/soloist_release_arm64.tar.gz"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl --fail --location -o "$tmpdir/soloist.tar.gz" "$x86_64Url"
tar -xzf "$tmpdir/soloist.tar.gz" -C "$tmpdir"
chmod +x "$tmpdir/soloist"

# Version string looks like: soloist 1.3.7.478 build 1787400071 (20260822) (gb24005ef46) (linux/x86_64)
newVersion="$("$tmpdir/soloist" --version | awk '{print $2}')"
currentVersion="$(NIXPKGS_ALLOW_UNFREE=1 nix eval --impure --raw -f . soloist.version)"

if [[ "$newVersion" == "$currentVersion" ]]; then
  echo "soloist: package is up-to-date ($currentVersion), but re-pinning anyway since builds expire after 90 days"
fi

update() {
  local system="$1" url="$2"
  local prefetched hash
  prefetched="$(nix-prefetch-url --unpack "$url")"
  hash="$(nix-hash --type sha256 --to-sri "$prefetched")"
  update-source-version --system="$system" --ignore-same-version soloist "$newVersion" "$hash" "$url"
}

update "x86_64-linux" "$x86_64Url"
update "aarch64-linux" "$aarch64Url"
