# Ensure CLI passes down arguments
{ ... }@args:

import ../../lib/eval-with-configuration.nix (
  args
  // {
    configuration = [ (import ./configuration.nix) ];
    additionalHelpInstructions = { device }: ''
      Build a GNOME system with a zstd-compressed btrfs root inside LUKS:

       $ nix-build examples/gnome --argstr device ${device} -A outputs.default

      The build-time LUKS passphrase and the user password are both `1234`.
      Change the passphrase on the device after the first boot.
      Flash the system image to userdata; the Android system partition is too small.
    '';
  }
)
