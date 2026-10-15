{
  stdenv,
  lib,
  fetchFromGitHub,
  buildPackages,
  kernel,
  initrd,
  cmdline,
  deviceTree,
  boardName,
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
  pname = "mobile-nixos-google-gs201-boot.img";
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
        cat << 'EOF' > configs/tangorpro_defconfig
    CONFIG_POSITION_INDEPENDENT=y
    CONFIG_LINUX_KRNL_HEADER_IMG=y
    CONFIG_COMPRESS_LZ4=y
    CONFIG_EARLYCON=y
    CONFIG_FDT_BUF_SIZE=1000000
    CONFIG_EXYNOS_GOOGLE_GS201=y
    CONFIG_GOOGLE_TANGORPRO=y
    CONFIG_TEXT_BASE=0xa0011010
    CONFIG_PAYLOAD_ENTRY=0x80000000
    CONFIG_RAMDISK_ENTRY=0x8d000000
    EOF
  '';

  configurePhase = ''
    runHook preConfigure
    cp ${kernel}/${kernel.target} blob/Image
    cp ${kernel}/dtbs/exynos/google/${deviceTree} blob/dtb
    cp ${initrd} blob/ramdisk
    chmod +w blob/dtb
    fdtput -t s blob/dtb /chosen bootargs ${lib.escapeShellArg cmdline}
    make $makeFlags ${boardName}_defconfig
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
