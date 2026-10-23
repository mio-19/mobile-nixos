# Cross-compilation fixes for the GNOME closure.
#
# These stay with this example. modules/cross-workarounds.nix is for the
# basic system; applying them there would rebuild systemd and cargo for
# every cross build.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # This repo selects the device with nixpkgs.hostPlatform, so
  # nixpkgs.crossSystem stays null. Match modules/system-target.nix.
  hasLocalSystem = (builtins.tryEval config.nixpkgs.localSystem).success;
  isCross = hasLocalSystem && config.mobile.system.system != config.nixpkgs.localSystem.system;
in
lib.mkIf isCross {
  nixpkgs.overlays = [
    (
      final: prev:
      # The cargo that compiles for the device lives in the build package
      # set (host == build, target == device). Meson never passes --target.
      lib.optionalAttrs (prev.stdenv.hostPlatform != prev.stdenv.targetPlatform) {
        cargo = prev.buildPackages.writeShellScriptBin "cargo" ''
          export CARGO_BUILD_TARGET=${prev.stdenv.targetPlatform.rust.rustcTarget}
          ${prev.cargo}/bin/cargo "$@"
          status=$?
          if [[ $status -ne 0 ]]; then
            exit $status
          fi
          # Meson copies target/<profile>/<name>. Cargo --target writes
          # target/<triple>/<profile>/<name>. Mirror the top-level files.
          is_build=0
          target_dir=target
          profile=debug
          prev_arg=
          for arg in "$@"; do
            case "$arg" in
              build) is_build=1 ;;
              --release) profile=release ;;
              --target-dir=*) target_dir="''${arg#--target-dir=}" ;;
              --profile=*) profile="''${arg#--profile=}" ;;
            esac
            if [[ "$prev_arg" == "--target-dir" ]]; then
              target_dir=$arg
            fi
            if [[ "$prev_arg" == "--profile" ]]; then
              profile=$arg
            fi
            prev_arg=$arg
          done
          built="$target_dir/$CARGO_BUILD_TARGET/$profile"
          if [[ $is_build -eq 1 && -d "$built" ]]; then
            mkdir -p "$target_dir/$profile"
            find "$built" -maxdepth 1 -type f -exec cp -a {} "$target_dir/$profile/" \;
          fi
        '';
      }
      // lib.optionalAttrs (prev.stdenv.hostPlatform != prev.stdenv.buildPlatform) {
        # Cross clang -target bpf does not see the target linux headers, so
        # systemd's BPF objects fail with "linux/types.h file not found".
        systemd = prev.systemd.override { withLibBPF = false; };
        # gi-docgen is a native tool; the cross pkg-config lookup fails and
        # meson then tries to wrap-download it, which the sandbox forbids.
        gupnp-av = prev.gupnp-av.overrideAttrs (old: {
          outputs = [
            "out"
            "dev"
          ];
          mesonFlags = [ "-Dgtk_doc=false" ];
          postFixup = "";
        });
        # Meson looks up `python3` as a native program for the GI overrides.
        gom = prev.gom.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.buildPackages.python3 ];
        });
        # gdbus-codegen is a native Python tool shipped in glib.dev.
        gnome-session = prev.gnome-session.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.buildPackages.glib.dev ];
        });
        # find_program('gjs') refuses the aarch64 interpreter. Point Meson
        # at it through the cross file, and skip gi-docgen.
        gnome-shell = prev.gnome-shell.overrideAttrs (old: {
          outputs = [ "out" ];
          mesonFlags = (builtins.filter (flag: flag != "-Dgtk_doc=true") (old.mesonFlags or [ ])) ++ [
            "-Dgtk_doc=false"
          ];
          preConfigure = (old.preConfigure or "") + ''
            gjs_console="$(''${PKG_CONFIG} --variable=gjs_console gjs-1.0)"
            gjs_bin="$(dirname "$gjs_console")/gjs"
            test -x "$gjs_bin"
            echo "[binaries]" > gjs-cross.ini
            echo "gjs = '$gjs_bin'" >> gjs-cross.ini
            mesonFlags+=" --cross-file=$(pwd)/gjs-cross.ini"
          '';
        });
        # Cross builds cannot run the CLI to emit man pages or shell
        # completions (native pygobject vs target typelibs), and gtk-doc
        # would execute the built library. The daemon itself still builds.
        power-profiles-daemon = prev.power-profiles-daemon.overrideAttrs (old: {
          outputs = [ "out" ];
          mesonFlags =
            (builtins.filter (flag: flag != "-Dgtk_doc=true" && !(lib.hasPrefix "-Dzshcomp=" flag)) (
              old.mesonFlags or [ ]
            ))
            ++ [
              "-Dgtk_doc=false"
              "-Dmanpage=disabled"
              "-Dbashcomp=disabled"
              "-Dzshcomp="
            ];
        });
      }
    )
  ];

  # Its Meson setup wants a native python3 with gi.
  services.gnome.gnome-browser-connector.enable = false;

  environment.gnome.excludePackages = with pkgs; [
    # Installed scripts pick up the native Python interpreter.
    gnome-music
    # Cross pkg-config cannot see the native blueprint-compiler.
    showtime
    # File previewer; its Meson setup wants to execute the aarch64 gjs.
    sushi
  ];
}
