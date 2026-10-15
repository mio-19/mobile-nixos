/**
  Pixel 9 Pro XL (google-komodo) Dual-Boot (Slot A/B) + ZFS Native Encryption Guide
  =================================================================================

  ARCHITECTURE & DUAL-BOOT OVERVIEW:
  ----------------------------------
  1. Slot Allocation:
     - Slot A: Retains Stock Android (GKI kernel in boot_a, init_boot_a,
       vendor_boot_a, dtbo_a, and dynamic partitions inside `super`).
     - Slot B: Runs Mobile NixOS with ZFS (boot_b via uniLoader + mainline 7.3
       kernel + zumapro-komodo.dtb + Mobile NixOS stage-1 initrd).

  2. Dedicated Storage Partitioning:
     - On Google Tensor (G4 / zumapro), `userdata` is shared across both slots.
     - Shrink Android's `userdata` partition and create a dedicated UFS partition
       labeled `nixos_root` for Mobile NixOS's ZFS storage pool.
     - Android's data remains untouched on Slot A.

  3. ZFS Pool & Native Dataset-Level Encryption:
     - The root and nix store datasets (`zroot/root`, `zroot/nix`) reside in the pool.
     - The user's home directory (`zroot/home/<username>`) is formatted with
       native ZFS filesystem-level encryption (AES-256-GCM).
     - The passphrase for the ZFS home dataset is set to match the user's login password.
     - On user login (TTY, LightDM, or Phosh), `security.pam.zfs` automatically
       loads the encryption key (`zfs load-key`) and mounts the home dataset.
     - On user logout, PAM automatically unmounts and unloads the key (`zfs unload-key`).

  ONE-TIME ZFS POOL & DATASET SETUP COMMANDS:
  -------------------------------------------
  From a recovery environment, installer, or fastbootd shell:

  1. Create the ZFS storage pool on the dedicated partition:
     # zpool create -O mountpoint=none -O atime=off -O compression=zstd \
         -O xattr=sa -O acltype=posixacl -f zroot /dev/disk/by-partlabel/nixos_root

  2. Create system datasets:
     # zfs create -o mountpoint=legacy zroot/root
     # zfs create -o mountpoint=legacy zroot/nix
     # zfs create -o mountpoint=none zroot/home

  3. Create the encrypted home directory dataset:
     # zfs create -o encryption=aes-256-gcm -o keyformat=passphrase \
         -o keylocation=prompt -o mountpoint=legacy zroot/home/user
     (Enter the user's login password when prompted)

  BUILD & FLASH INSTRUCTIONS:
  ---------------------------
  Build the boot image for Slot B:
    $ nix-build examples/google-komodo-dualboot-zfs -A outputs.android-bootimg

  Flash to Slot B:
    $ fastboot --set-active=b
    $ fastboot flash boot_b ./result
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
  # 2. ZFS Filesystem & Host Configuration
  # --------------------------------------------------------------------------
  # Required by ZFS to identify host pool associations
  networking.hostId = "8425e349";

  # Enable ZFS kernel module and userspace tooling
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-partlabel";

  # Root and system dataset mount points
  fileSystems."/" = {
    device = "zroot/root";
    fsType = "zfs";
  };

  fileSystems."/nix" = {
    device = "zroot/nix";
    fsType = "zfs";
  };

  fileSystems."/home/${user}" = {
    device = "zroot/home/${user}";
    fsType = "zfs";
    # Mounted dynamically by PAM on login; marked noauto for initial boot
    options = [
      "noauto"
      "zfsutil"
    ];
  };

  # --------------------------------------------------------------------------
  # 3. ZFS Dataset-Level Encryption & PAM Auto-Unlock on Login
  # --------------------------------------------------------------------------
  security.pam.zfs = {
    enable = true;
    # Prefix dataset for user home directories (unlocked as <homes>/<username>)
    homes = "zroot/home";
    mountRecursively = true;
    # On logout, automatically unmount and unload the encryption key
    noUnmount = false;
  };

  # --------------------------------------------------------------------------
  # 4. User Account & Touch-Friendly Desktop (Phosh)
  # --------------------------------------------------------------------------
  users.users."${user}" = {
    isNormalUser = true;
    # Password matching the ZFS dataset passphrase
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

  # Stage-1 bootsplash GUI
  mobile.beautification = {
    splash = true;
    silentBoot = false;
  };

  services.xserver.enable = true;
  services.displayManager.autoLogin = {
    # Disabled auto-login so user logs in with password, allowing PAM to unlock ZFS
    enable = false;
  };
  services.xserver.displayManager.lightdm.enable = true;

  services.xserver.desktopManager.phosh = {
    enable = true;
    user = "${user}";
    group = "users";
    phocConfig.xwayland = "immediate";
  };

  # --------------------------------------------------------------------------
  # 5. Networking & Tooling
  # --------------------------------------------------------------------------
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    zfs
    parted
    e2fsprogs
    epiphany
    gnome-console
  ];
}
