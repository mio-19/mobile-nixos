# Ensure CLI passes down arguments
{
  device ? "google-komodo",
  ...
}@args:

import ../../lib/eval-with-configuration.nix (
  args
  // {
    inherit device;
    configuration = [ (import ./configuration.nix) ];
    additionalHelpInstructions = { device }: ''
      Build the boot image for Slot B:
        $ nix-build examples/google-komodo-dualboot-zfs -A outputs.android-bootimg

      Build the system output for Slot B:
        $ nix-build examples/google-komodo-dualboot-zfs -A outputs.default
    '';
  }
)
