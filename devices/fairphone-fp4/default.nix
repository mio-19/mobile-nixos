{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../families/sm7325-mainline
  ];

  mobile.device.name = "fairphone-fp4";
  mobile.device.identity = {
    name = "Fairphone 4";
    manufacturer = "Fairphone";
  };
  mobile.device.supportLevel = "best-effort";

  mobile.hardware = {
    ram = 1024 * 6;
    screen = {
      width = 1080;
      height = 2340;
    };
  };

  # The kernel tree uses the upstream SM7225 Fairphone 4 device tree name.
  mobile.system.android.dtb = lib.mkForce "dtbs/qcom/sm7225-fairphone-fp4.dtb";
  mobile.system.android.device_name = "FP4";

  # Disable systemd BPF helpers: Nixpkgs' cross build currently omits the
  # target Linux UAPI headers required to compile them.
  services.dbus.implementation = "dbus";

  nixpkgs.overlays = [
    (final: prev: {
      systemd = prev.systemd.override { withLibBPF = false; };
    })
  ];

  # The shared family currently expects the SM7325 firmware directory layout.
  # FP4 blobs are device specific and are not part of NixOS firmware yet.
  mobile.device.firmware = pkgs.runCommand "fairphone-fp4-firmware-placeholder" { } ''
    mkdir -p $out/lib/firmware/qcom/sm7325
  '';
}
