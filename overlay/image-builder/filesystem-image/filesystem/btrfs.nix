{
  config,
  lib,
  pkgs,
  ...
}:

let
  enabled = config.filesystem == "btrfs";
  inherit (lib)
    escapeShellArg
    mkIf
    mkMerge
    mkOption
    optionalString
    types
    ;

  inherit (config) label;
  inherit (config.btrfs) partitionID compression;
in
{
  options.btrfs = {
    partitionID = mkOption {
      type = types.nullOr config.helpers.types.uuid;
      example = "45454545-4545-4545-4545-454545454545";
      default = null;
      description = ''
        Volume ID of the filesystem.
      '';
    };

    compression = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "zstd";
      description = ''
        Compression passed to `mkfs.btrfs --compress` when the image is
        populated with `-r`.

        Examples: `zstd`, `zstd:3`, `lzo`, `zlib`, `zlib:9`.
        Leave unset to store extents uncompressed.
      '';
    };
  };

  config = mkMerge [
    { availableFilesystems = [ "btrfs" ]; }
    (mkIf enabled {
      nativeBuildInputs = with pkgs.buildPackages; [
        btrfs-progs
      ];

      blockSize = config.helpers.size.KiB 4;
      sectorSize = lib.mkDefault 512;

      # Generated an empty filesystem, it was 114294784 bytes long.
      # Rounded up to 110MiB.
      minimumSize = config.helpers.size.MiB 110;

      # Metadata and chunk overhead on top of the file payload.
      # `--shrink` trims the unused tail after mkfs.
      computeMinimalSize = ''
        size=$(( size + size / 8 + ${toString (config.helpers.size.MiB 64)} ))
      '';

      buildPhases = {
        copyPhase = ''
          mkfs.btrfs \
            -r . \
            ${optionalString (compression != null) "--compress ${escapeShellArg compression}"} \
            ${optionalString (partitionID != null) "-U ${partitionID}"} \
            ${optionalString (label != null) "-L ${escapeShellArg label}"} \
            ${optionalString (config.size == null) "--shrink"} \
            "$img"
        '';

        checkPhase = ''
          faketime -f "1970-01-01 00:00:01" btrfs check "$img"
        '';
      };
    })
  ];
}
