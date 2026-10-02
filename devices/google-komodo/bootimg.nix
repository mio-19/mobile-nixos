{
  stdenv,
  lib,
  fetchFromGitHub,
  buildPackages,
  kernel,
  initrd,
  cmdline,
}:

let
  mkbootimgSource = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_system_tools_mkbootimg";
    rev = "808ecd09666ffe0ff5800f02af693abce56eb395";
    hash = "sha256-z7KklKf0dTyt7ZoUiZrMYRzU3h+WuLnc355LRtFMs2s=";
  };
in
stdenv.mkDerivation {
  pname = "mobile-nixos-google-komodo-boot.img";
  version = "2026-08-29";

  src = fetchFromGitHub {
    owner = "Trijal08";
    repo = "uniLoader";
    rev = "c2642b1634e9465863358f1ef6a0116af1d15822";
    hash = "sha256-3a6GMgNP9SKDo9IrY5gqyz7uy01C7yc2Sa7UljGLI8U=";
  };

  nativeBuildInputs = with buildPackages; [
    bison
    dtc
    flex
    lz4
    python3
  ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  enableParallelBuilding = true;
  dontStrip = true;

  makeFlags = [
    "ARCH=aarch64"
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
  ];

  postPatch = ''
    patchShebangs scripts
  '';

  configurePhase = ''
    runHook preConfigure
    cp ${kernel}/${kernel.target} blob/Image
    cp ${kernel}/dtbs/exynos/google/zumapro-komodo.dtb blob/dtb
    cp ${initrd} blob/ramdisk
    chmod +w blob/dtb
    fdtput -t s blob/dtb /chosen bootargs ${lib.escapeShellArg cmdline}
    make $makeFlags komodo_defconfig
    runHook postConfigure
  '';

  installPhase = ''
    runHook preInstall
    python3 ${mkbootimgSource}/mkbootimg.py \
      --header_version 4 \
      --kernel uniLoader.lz4 \
      --cmdline ${lib.escapeShellArg cmdline} \
      --output $out
    runHook postInstall
  '';
}
