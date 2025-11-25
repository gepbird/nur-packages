pkgs:
with pkgs;

buildGoModule (finalAttrs: {
  pname = "go-foks";
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "foks-proj";
    repo = "go-foks";
    tag = "v${finalAttrs.version}";
    hash = "sha256-/+Z/afzj5y4CVU3qRymSIUzCabT2jAEBlKKoYgKlPRE=";
  };

  vendorHash = "sha256-nTHsYMQjVaQM+g2MM++/BDVYfzIM4CaMM6eK5GQE6Cc=";

  nativeBuildInputs = [
    pkg-config
    pcsclite
    pcsclite.lib
  ];

  buildInputs = [
    pcsclite
    pcsclite.lib
  ];

  doCheck = false;
})
