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
    soc = "google-tensor-g4";
    ram = lib.mkDefault (1024 * 16);
  };

  mobile.boot.stage-1 = {
    compression = "gzip";
    kernel = {
      package = pkgs.callPackage ./kernel {
        configfile = (../..) + "/${config.mobile.device.name}/kernel/config.aarch64";
      };
      modular = true;
      allowMissingModules = false;
      modules = [
        # Always-on compute, its channel transport and the clients the
        # touchscreen and wake-gesture stacks depend on.
        "aoc"
        "aoc-channel"
        "aoc-usf"
        "touch_bus_negotiator"
        "syna_tcm"
      ];
    };
    firmware = lib.optional (config.mobile.device.firmware != null) config.mobile.device.firmware;
  };

  mobile.kernel.structuredConfig = [
    (
      helpers: with helpers; {
        RUST = no;
        DRM_EXYNOS = yes;
        DRM_EXYNOS9_DECON = yes;
        DRM_PANTHOR = yes;
        TEE = yes;
        TRUSTY = module;
        GOOGLE_AOC = module;
        GOOGLE_AOC_CHANNEL = module;
        GOOGLE_AOC_USF = module;
        AOC_USF_IIO = module;
        INPUT_AOC_GESTURE_WAKE = module;
        TOUCHSCREEN_TBN = module;
        # BCM4390 connectivity is owned by the AoC; the Bluetooth transport
        # lives in the kernel even though Wi-Fi uses the downstream bcmdhd.
        BT_HCIAOC = module;
        BCMDHD_BCM4390 = module;
        # Torch/flash LED.
        LEDS_CLASS_FLASH = yes;
        LEDS_LM3644 = module;
        # The tree boots through DRM_SIMPLEDRM (mutually exclusive with the
        # generic FB_SIMPLE) and keeps the upstream full-preemption model.
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
    deviceTree = "zumapro-${config.mobile.system.android.device_name}.dtb";
    boardName = config.mobile.system.android.device_name;
  };

  boot.kernelParams = [
    "earlycon=exynos4210,0x10870000"
    "clk_ignore_unused"
    "regulator_ignore_unused"
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
