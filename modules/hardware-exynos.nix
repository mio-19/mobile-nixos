{ config, lib, pkgs, ... }:

let
  inherit (lib) mkMerge mkOption mkIf types;
  cfg = config.mobile.hardware.socs;
  anyExynos = lib.any (v: v) [
    cfg.exynos-7880.enable
    cfg.google-tensor-g4.enable
  ];
in
{
  options.mobile = {
    hardware.socs.exynos-7880.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is Exynos 7880";
    };
    hardware.socs.google-tensor-g4.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable when SOC is Google Tensor G4 (zumapro)";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.exynos-7880.enable {
        system.system = "aarch64-linux";
        quirks.fb-refresher.enable = true;
      };
    }
    {
      mobile.system.system = mkIf cfg.google-tensor-g4.enable "aarch64-linux";
    }
    (mkIf anyExynos {
      mobile.kernel.structuredConfig = [
        (helpers: with helpers; {
          ARCH_EXYNOS = lib.mkDefault yes;
        })
      ];
    })
  ];
}
