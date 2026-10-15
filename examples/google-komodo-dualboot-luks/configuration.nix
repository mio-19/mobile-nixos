/**
  Pixel 9 Pro XL (google-komodo) Dual-Boot (Slot A/B) + LUKS Configuration Guide
  ==============================================================================

  ARCHITECTURE & DUAL-BOOT SETUP:
  ------------------------------
  1. Slot Allocation:
     - Slot A: Retains Stock Android (GKI kernel in boot_a, init_boot_a,
       vendor_boot_a, dtbo_a, and dynamic partitions inside `super`).
     - Slot B: Runs Mobile NixOS (boot_b via uniLoader + mainline 7.3 kernel +
       zumapro-komodo.dtb + Mobile NixOS stage-1 initrd).

  2. Storage & Partitioning:
     - On Google Tensor (G4 / zumapro), `userdata` is shared across both slots.
     - Flashing Mobile NixOS over `userdata` directly will destroy Android.
     - To dual-boot without data loss, create a dedicated partition labeled `nixos_root`
       (or identify it by partition UUID) using one of the two methods below.

  SETTING UP THE PARTITION LAYOUT FROM DEFAULT ANDROID:
  -----------------------------------------------------
  Stock Android uses a GPT layout on UFS storage (/dev/block/by-name/):
  - Slotted boot partitions: boot_a/boot_b, init_boot_a/init_boot_b, vendor_boot_a/vendor_boot_b, dtbo_a/dtbo_b
  - Shared dynamic container: `super` (holds system_a/b, vendor_a/b, product_a/b)
  - Shared user data: `userdata` (occupies almost all remaining disk space)

  METHOD A: Resizing `userdata` with parted (Recommended for 32GB+ installations)
  1. Boot into a recovery environment with root shell / ADB (or temporary TWRP/initramfs):
     $ adb reboot recovery
  2. Unmount userdata if mounted:
     # umount /data /dev/block/by-name/userdata 2>/dev/null || true
  3. Check and shrink the filesystem (e2fsck + resize2fs for ext4, or backup/restore for f2fs):
     # e2fsck -fy /dev/block/by-name/userdata
     # resize2fs /dev/block/by-name/userdata 64G  (e.g., shrink to 64GB)
  4. Inspect the partition table on the UFS LUN containing userdata (typically /dev/block/sda):
     # parted /dev/block/sda print
     Note the partition number of `userdata` (e.g. 52) and its start sector.
  5. Shrink the `userdata` partition boundary to match the resized filesystem:
     # parted /dev/block/sda resizepart 52 <start_sector + 64GB in sectors>
  6. Create a new partition in the newly unallocated space:
     # parted /dev/block/sda mkpart nixos_root ext4 <end_of_userdata_sector> 100%
  7. Label the new partition:
     # parted /dev/block/sda name <new_part_num> nixos_root
  8. Inform the kernel:
     # partprobe /dev/block/sda

  METHOD B: Carving a logical partition inside `super` via fastbootd
  If your `super` partition has unallocated space, or if you delete unused slot-B dynamic partitions:
  1. Reboot to fastbootd:
     $ fastboot reboot fastboot
  2. Create a new logical partition inside super:
     $ fastboot create-logical-partition nixos_root 17179869184  (16 GiB)
  3. Flash the system image directly:
     $ fastboot flash nixos_root ./result-rootfs/system.img

  3. LUKS Encryption & On-Screen Touch Keyboard:
     - `mobile.rootfs.luks.enable = true` encrypts the generated rootfs image with
       a temporary build-time passphrase.
     - `mobile.beautification.splash = true` activates the stage-1 touch splash GUI.
     - The `google-zumapro` device family includes Synaptics touchscreen drivers
       (`syna_tcm`, `touch_bus_negotiator`, `aoc`) in the stage-1 initrd, enabling
       touchscreen password entry during boot.
     - After first boot, change the passphrase:
       $ sudo cryptsetup luksChangeKey /dev/disk/by-uuid/<LUKS-UUID>

  4. Slot Protection & Boot Control:
     - `mobile.boot.boot-control.enable = true` marks the boot as successful so the
       bootloader does not roll back to Slot A after a reboot.

  BUILD & FLASH INSTRUCTIONS:
  ---------------------------
  Build the boot image and encrypted rootfs:
    $ nix-build examples/google-komodo-dualboot-luks -A outputs.android-bootimg
    $ nix-build examples/google-komodo-dualboot-luks -A outputs.default

  Reboot to fastboot (Power + Vol Down):
    $ fastboot --set-active=b
    $ fastboot flash boot_b ./result
    $ fastboot flash nixos_root ./result-rootfs/system.img
    $ fastboot reboot

  SWITCHING OS:
  -------------
  - To boot Stock Android: `fastboot --set-active=a && fastboot reboot`
  - To boot Mobile NixOS:  `fastboot --set-active=b && fastboot reboot`
*/

{
  config,
  lib,
  pkgs,
  ...
}:

let
  user = "user";
  # Change this to match the partition UUID of your designated slot-B root partition
  luksContainerUUID = "44444444-4444-4444-8888-888888888888";
in
{
  imports = [
    ../common-configuration.nix
  ];

  # --------------------------------------------------------------------------
  # 1. Slot B & A/B Boot Control
  # --------------------------------------------------------------------------
  # Mark successful boots in bootloader metadata to prevent rollback to Slot A
  mobile.boot.boot-control.enable = true;

  # Android system partition type & destination
  mobile.system.type = "android";
  mobile.system.android = {
    ab_partitions = true;
    # Points to your dedicated partition rather than overwriting Android userdata
    system_partition_destination = lib.mkForce "/dev/disk/by-partlabel/nixos_root";
  };

  # --------------------------------------------------------------------------
  # 2. LUKS Full Disk Encryption & Stage-1 Touch GUI
  # --------------------------------------------------------------------------
  mobile.rootfs.luks = {
    enable = true;
    uuid = luksContainerUUID;
    passphrase = "1234"; # Initial build-time passphrase; change after first boot
  };

  # Touchscreen splash GUI for on-screen LUKS passphrase entry
  mobile.beautification = {
    splash = true;
    silentBoot = false; # Set to false during initial bringup to see logs
  };

  # Performance & discard settings for the LUKS device
  boot.initrd.luks.devices."LUKS-MOBILE-ROOTFS" = {
    device = "/dev/disk/by-uuid/${luksContainerUUID}";
    allowDiscards = true;
    bypassWorkqueues = true;
  };

  # --------------------------------------------------------------------------
  # 3. User Account & Touch-Friendly Desktop (Phosh)
  # --------------------------------------------------------------------------
  users.users."${user}" = {
    isNormalUser = true;
    password = "1234";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "feedbackd"
    ];
  };

  services.xserver.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = "${user}";
  };
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.displayManager.lightdm.greeter.enable = false;

  services.xserver.desktopManager.phosh = {
    enable = true;
    user = "${user}";
    group = "users";
    phocConfig.xwayland = "immediate";
  };

  # --------------------------------------------------------------------------
  # 4. Networking & Packages
  # --------------------------------------------------------------------------
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    cryptsetup
    lvm2
    e2fsprogs
    parted
    epiphany
    gnome-console
  ];
}
