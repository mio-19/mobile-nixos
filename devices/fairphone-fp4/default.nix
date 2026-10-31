{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../families/sm7325-mainline
    ./sound.nix
  ];

  # Keep the FP4 on the SM6350/SM7225 7.2 kernel line used by Nura without
  # changing the kernel used by other devices in the shared family.
  mobile.boot.stage-1.kernel.package = lib.mkForce (pkgs.callPackage ./kernel { });

  mobile.device.name = "fairphone-fp4";
  mobile.device.identity = {
    name = "Fairphone 4";
    manufacturer = "Fairphone";
  };
  mobile.device.supportLevel = "best-effort";

  # SM7225 uses the SM6350-family pin controller and interconnect drivers.
  mobile.hardware.soc = lib.mkForce "qualcomm-sm7225";

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
  # Install to the active A/B slot only so the other slot can retain Android.
  mobile.system.android.ab_partitions = lib.mkForce false;
  # Nura's FP4 slot install updates boot only; leave recovery partitions alone.
  mobile.system.android.has_recovery_partition = lib.mkForce false;

  # qbootctl is the Qualcomm A/B slot manager used by Nura on the FP4.
  # Let it mark this OS's slot successful after reaching multi-user.
  mobile.boot.boot-control.enable = lib.mkForce false;
  environment.systemPackages = [
    pkgs.qbootctl
    pkgs.fairphone-fp4-alsa-ucm
  ];
  systemd.services.qbootctl-mark-boot-successful = {
    description = "Mark the current Qualcomm boot slot successful";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.qbootctl}/bin/qbootctl -m";
    };
  };

  # Match the modules Nura loads in its initramfs for the display.
  mobile.boot.stage-1.kernel.modules = [
    "msm"
    "panel-himax-hx83112a"
  ];

  # The shared family defaults this modem quirk on for SM7325 devices.
  mobile.quirks.qualcomm.sm7325-modem.enable = lib.mkForce false;
  mobile.quirks.qualcomm.sm6350-modem.enable = true;

  # Disable systemd BPF helpers: Nixpkgs' cross build currently omits the
  # target Linux UAPI headers required to compile them.
  services.dbus.implementation = "dbus";

  nixpkgs.overlays = [
    (final: prev: {
      systemd = prev.systemd.override { withLibBPF = false; };
    })
  ];

  mobile.device.firmware = pkgs.callPackage ./firmware { };
  mobile.quirks.qualcomm.hexagonrpc.enable = true;
  mobile.quirks.qualcomm.hexagonrpc.firmware = config.mobile.device.firmware;
  mobile.quirks.audio.alsa-ucm-meld = true;
  services.udev.extraRules = lib.mkAfter ''
    # The FP4's accelerometer is mounted upside down relative to screen axes.
    SUBSYSTEM=="misc", KERNEL=="fastrpc-*", ENV{ACCEL_MOUNT_MATRIX}+="-1, 0, 0; 0, -1, 0; 0, 0, 1"
    SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT}=="1", SUBSYSTEMS=="input", ATTRS{name}=="aw8695-haptics", TAG+="uaccess", ENV{FEEDBACKD_TYPE}="vibra"
  '';

}
