{
  mobile-nixos,
  fetchFromGitHub,
  ...
}:

mobile-nixos.kernel-builder {
  version = "7.3.0-rc6";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "derekross";
    repo = "linux-omarchy-mobile";
    rev = "cb50dd686ccc6b35b7c529fa217d81508207ecef";
    hash = "sha256-m79NMYhKKlmWbxCkV275Wr2oL5yV95dy2NQYFgFGlS8=";
  };

  postPatch = ''
    cp ${./gs201-tangorpro.dts} arch/arm64/boot/dts/exynos/google/gs201-tangorpro.dts
    sed -i '/gs201-cheetah.dtb/a \\tgs201-tangorpro.dtb \\' arch/arm64/boot/dts/exynos/google/Makefile
    sed -i '/DTC_FLAGS_gs201-cheetah/a DTC_FLAGS_gs201-tangorpro += -@' arch/arm64/boot/dts/exynos/google/Makefile
  '';

  isModular = true;
  isCompressed = false;
  enableForceLogoPatch = false;
}
