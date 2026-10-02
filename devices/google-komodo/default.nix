{
  config,
  lib,
  pkgs,
  ...
}:

{
  mobile.device.name = "google-komodo";
  mobile.device.identity = {
    name = "Pixel 9 Pro XL";
    manufacturer = "Google";
  };
  mobile.device.supportLevel = "best-effort";

  mobile.hardware = {
    soc = "google-tensor-g4";
    ram = 1024 * 16;
    screen = {
      width = 1344;
      height = 2992;
    };
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
        DRM_PANEL_GOOGLE_KOMODO = yes;
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
        # Speaker amplifiers and torch LED.
        SND_SOC_GOOGLE_AOC = module;
        SND_SOC_CS35L41_SPI = module;
        SND_SOC_CS35L41_I2C = module;
        LEDS_CLASS_FLASH = yes;
        LEDS_LM3644 = module;
      }
    )
  ];

  mobile.system.type = "android";
  mobile.system.android = {
    ab_partitions = true;
    device_name = "komodo";
    system_partition_destination = "userdata";
  };

  mobile.outputs.android.android-bootimg = pkgs.callPackage ./bootimg.nix {
    kernel = config.mobile.outputs.stage-0.mobile.boot.stage-1.kernel.package;
    initrd = config.mobile.outputs.initrd;
    cmdline = lib.concatStringsSep " " config.boot.kernelParams;
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
