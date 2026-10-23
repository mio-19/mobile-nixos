# GNOME with a zstd btrfs root inside a LUKS container.
#
# Safe to import from an end-user configuration. The passphrase is the
# well-known build-time value `1234`; change it on the device.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  user = "alice";
in
{
  imports = [
    ../common-configuration.nix
  ];

  documentation.enable = false;

  # A GNOME closure does not fit the Android system partition.
  mobile.system.android.system_partition_destination = "userdata";

  mobile.rootfs.luks.enable = true;

  # mkDefault so this merges with the rootfs and LUKS image settings.
  # A plain definition would drop those mkDefault values (encrypt, label, …).
  mobile.generatedFilesystems.rootfs = lib.mkDefault {
    filesystem = lib.mkForce "btrfs";
    btrfs = {
      partitionID = "45454545-4545-4545-4545-454545454545";
      compression = "zstd";
    };
  };

  # Higher priority than the LUKS module, so the mapper device has to be
  # repeated here. Stage-1 can only grow ext filesystems; grow btrfs later.
  fileSystems."/" = {
    device = "/dev/mapper/LUKS-MOBILE-ROOTFS";
    fsType = "btrfs";
    autoResize = false;
    options = [
      "compress=zstd"
      "discard=async"
    ];
  };

  boot.initrd.luks.devices."LUKS-MOBILE-ROOTFS" = {
    device = "/dev/disk/by-uuid/${config.mobile.rootfs.luks.uuid}";
    allowDiscards = true;
  };

  # The flashed image is smaller than userdata. Open the full partition, then
  # grow the filesystem.
  boot.postBootCommands = ''
    if [ -b /dev/mapper/LUKS-MOBILE-ROOTFS ]; then
      ${pkgs.cryptsetup}/bin/cryptsetup resize LUKS-MOBILE-ROOTFS || echo "cryptsetup resize failed"
    fi
    ${pkgs.btrfs-progs}/bin/btrfs filesystem resize max / || echo "btrfs resize failed"
  '';

  users.users.${user} = {
    isNormalUser = true;
    password = "1234";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
  };

  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = user;
  };

  # Games and the IDE stack dwarf a phone image.
  services.gnome.games.enable = false;
  services.gnome.core-developer-tools.enable = false;

  environment.systemPackages = with pkgs; [
    gnome-console
    epiphany
  ];
}
