{
  mobile-nixos,
  fetchFromGitHub,
  ...
}:

mobile-nixos.kernel-builder {
  version = "7.3.0-rc5";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "Trijal08";
    repo = "kernel-mainline";
    rev = "6854337b2a38953edf1f46a02aef132e10e8ba2b";
    hash = "sha256-MMurCANKhySO9/4nFeTIL0B9WE07YQ6bc6HsJGJopoY=";
  };

  isModular = true;
  isCompressed = false;
  enableForceLogoPatch = false;
}
