GNOME with a zstd-compressed btrfs root inside LUKS. The build-time passphrase
and the user password are both `1234`. Change the LUKS passphrase on the device
after the first boot (`cryptsetup luksChangeKey`).

GNOME is not part of the cross-compilation canaries. Building it for another
architecture needs further nixpkgs workarounds.

## Building

```
 $ nix-build examples/gnome --argstr device DEVICE-NAME -A outputs.default
```

For the OnePlus 6:

```
 $ nix-build examples/gnome --argstr device oneplus-enchilada -A outputs.default
```

## Installing

`result/flash-critical.sh` flashes the boot image only. The system image is
larger than the Android system partition, so flash it to userdata:

```
 $ fastboot flash --slot=all boot result/boot.img
 $ fastboot flash userdata result/system.img
```

Follow the device page before the first mainline boot. On the OnePlus 6 that
means erasing `dtbo_a` and `dtbo_b`.

The first boot grows the LUKS volume and the btrfs filesystem to fill userdata.
GDM signs in as `alice`.
