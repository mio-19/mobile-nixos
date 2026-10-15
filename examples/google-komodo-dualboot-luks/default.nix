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
        $ nix-build examples/google-komodo-dualboot-luks -A outputs.android-bootimg

      Build the LUKS-encrypted root filesystem image:
        $ nix-build examples/google-komodo-dualboot-luks -A outputs.default
    '';
  }
)
