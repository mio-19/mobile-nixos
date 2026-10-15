{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./sound.nix
  ];

  mobile.device.supportLevel = lib.mkDefault "best-effort";

  mobile.hardware = {
    soc = "google-tensor-g2";
    ram = lib.mkDefault (1024 * 8);
  };

  mobile.boot.stage-1 = {
    compression = "gzip";
    kernel = {
      package = pkgs.callPackage ./kernel { };
      modular = true;
      allowMissingModules = false;
      modules = [
        # Always-on compute, its channel transport and the clients the
        # touchscreen and wake-gesture stacks depend on.
        "aoc"
        "aoc-channel"
        "aoc-usf"
        "touch_bus_negotiator"
        "nvt_touch"
      ];
    };
    firmware = lib.optional (config.mobile.device.firmware != null) config.mobile.device.firmware;
  };

  mobile.kernel.structuredConfig = [
    (
      helpers: with helpers; {
        RUST = no;
        DRM_EXYNOS = yes;
        DRM_PANFROST = module;
        DRM_PANTHOR = module;
        TEE = yes;
        TRUSTY = module;
        GOOGLE_AOC = module;
        GOOGLE_AOC_CHANNEL = module;
        GOOGLE_AOC_USF = module;
        AOC_USF_IIO = module;
        INPUT_AOC_GESTURE_WAKE = module;
        TOUCHSCREEN_TBN = module;
        TOUCHSCREEN_NVT_TOUCH = module;
        BT_HCIUART_BCM = yes;
        BT_HCIAOC = module;
        BCMDHD = module;
        BRCMFMAC = module;
        BATTERY_MAX17042 = yes;
        MFD_MAX77759 = yes;
        CHARGER_MAX77759 = module;
        FB_SIMPLE = no;
        PREEMPT_VOLUNTARY = no;
        PREEMPT = yes;
      }
    )
  ];

  mobile.system.type = "android";
  mobile.system.android = {
    ab_partitions = true;
    system_partition_destination = "userdata";
  };

  mobile.outputs.android.android-bootimg = pkgs.callPackage ./bootimg.nix {
    kernel = config.mobile.outputs.stage-0.mobile.boot.stage-1.kernel.package;
    initrd = config.mobile.outputs.initrd;
    cmdline = lib.concatStringsSep " " config.boot.kernelParams;
    deviceTree = "gs201-${config.mobile.system.android.device_name}.dtb";
    boardName = config.mobile.system.android.device_name;
  };

  boot.kernelParams = [
    "earlycon=exynos4210,0x10a00000"
    "console=ttySAC0,115200"
    "clk_ignore_unused"
    "regulator_ignore_unused"
    "pd_ignore_unused"
  ];

  hardware.enableRedistributableFirmware = true;
  mobile.device.firmware = pkgs.callPackage ./firmware { };

  mobile.usb = {
    mode = "gadgetfs";
    idVendor = "18D1";
    idProduct = "D001";
    gadgetfs.functions = {
      adb = "ffs.adb";
      mass_storage = "mass_storage.0";
      rndis = "rndis.usb0";
    };
  };
}
