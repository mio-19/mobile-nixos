{
  runCommand,
  linux-firmware,
  ...
}:

# Redistributable firmware from the shared linux-firmware bundle that the
# Pixel 9 (Tensor G4 / zumapro) boards can use (Cirrus speaker amps, Broadcom
# connectivity). The board-specific tuning blobs (e.g. the `komodo`/`caiman`
# CS35L41 tunings, the BCM4390 NVRAM and the AoC firmware) ship only in the
# stock installation and are not redistributable; extract those and overlay
# them on top of this derivation.
runCommand "google-zumapro-firmware" { } ''
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
