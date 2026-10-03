# Build-time LUKS encryption for the generated root filesystem image.
#
# This is the declarative equivalent of what the installer does on-device: it
# produces an encrypted root filesystem image, unlockable with a known
# passphrase, so the default output can be flashed and booted straight through
# the LUKS stage-1 path. It is *not* a way to keep a secret; change the
# passphrase on the device after the first boot (e.g. `cryptsetup
# luksChangeKey`).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    types
    ;

  cfg = config.mobile.rootfs.luks;

  rootfs = config.mobile.generatedFilesystems.rootfs;

  # Shared with the (mkDefault) rootfs so existing `fileSystems` and
  # `boot.initrd.luks.devices` definitions keep matching.
  defaultUUID = "44444444-4444-4444-8888-888888888888";
in
{
  options.mobile.rootfs.luks = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Encrypt the generated root filesystem image with LUKS.

        Enable this, then define the matching unlock in
        `boot.initrd.luks.devices` and point the root filesystem at the opened
        mapper device.
      '';
    };

    passphrase = mkOption {
      type = types.str;
      default = "1234";
      description = ''
        Build-time passphrase used to encrypt the generated image.

        This is a well-known, insecure value embedded in the world-readable
        Nix store. Change it on the device after the first boot:

        ```
        cryptsetup luksChangeKey /dev/disk/by-...
        ```
      '';
    };

    uuid = mkOption {
      type = types.nullOr (
        types.strMatching "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
      );
      default = defaultUUID;
      description = ''
        UUID assigned to the LUKS container.

        Defaults to the same value the root filesystem uses, so the same
        `fileSystems`/`boot.initrd.luks.devices` definitions keep working
        whether or not the image is encrypted.
      '';
    };

    slackSpace = mkOption {
      type = types.int;
      default = 32;
      description = ''
        Space, in MiB, appended to the image to hold the LUKS header.
      '';
    };
  };

  config = mkIf (cfg.enable && config.mobile.rootfs.enableDefaultConfiguration) {
    # `mkDefault` so this merges with (rather than replaces) the rootfs
    # definitions from the rootfs module.
    mobile.generatedFilesystems.rootfs = lib.mkDefault {
      encrypt = true;
      encryptPassphrase = cfg.passphrase;
      encryptUUID = cfg.uuid;
      encryptSlackSpace = cfg.slackSpace;
    };

    # Convenience: pre-configure the LUKS unlock using the container UUID.
    # Point `fileSystems."/"` at `/dev/mapper/<name>` yourself, or rely on the
    # already-open device in your configuration.
    boot.initrd.luks.devices = lib.mkDefault {
      "LUKS-MOBILE-ROOTFS" = {
        device = "/dev/disk/by-uuid/${cfg.uuid}";
      };
    };
  };
}
