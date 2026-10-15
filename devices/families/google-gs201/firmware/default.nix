{
  runCommand,
  linux-firmware,
  ...
}:

# Redistributable firmware from the shared linux-firmware bundle that the
# Pixel Tablet (Tensor G2 / gs201) boards can use (Cirrus speaker amps, Broadcom
# connectivity). The board-specific tuning blobs (e.g. the `tangorpro`
# CS35L41 tunings, the BCM4389 NVRAM, the AoC firmware, the
# google/usf sensor registry) ship only in the
# stock installation and are not redistributable; extract those and overlay
# them on top of this derivation.
runCommand "google-gs201-firmware" { } ''
  firmware=$out/lib/firmware
  mkdir -p $firmware

  copy_if_present() {
    source="$1"
    if [ -e "$source" ]; then
      cp -vr --no-preserve=mode "$source" "$firmware"/
    fi
  }

  for path in \
    cirrus \
    brcm \
    exynos
  do
    copy_if_present "${linux-firmware}/lib/firmware/$path"
  done
''
