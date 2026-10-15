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
     - To dual-boot without data loss, shrink Android's `userdata` using
       `resize2fs` / `parted` (from a recovery environment or fastbootd) and create
       a dedicated partition labeled `nixos_root` (or identify it by partition UUID).
     - Android's data remains safe on Slot A.

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
