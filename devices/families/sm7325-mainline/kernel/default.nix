{
  mobile-nixos,
  fetchFromGitHub,
  ...
}:

# SC7280 is a compute variant of the SM7325
mobile-nixos.kernel-builder {
  version = "7.0.0";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "sc7280-mainline";
    repo = "linux";
    rev = "d7d0d4a111f11beb1a32f806cc16934f32f37583";
    hash = "sha256-aFFmGhblTEKukORSJ7jw4dkcQsPJAo6xiDFWka4uHr0=";
  };

  patches = [
    ./nothing-spacewar-audio.patch
  ];

  isModular = true;
  isCompressed = "gz";
}
