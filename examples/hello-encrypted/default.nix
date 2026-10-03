# Ensure CLI passes down arguments
{ ... }@args:

import ../../lib/eval-with-configuration.nix (
  args
  // {
    configuration = [
      ({ ... }: {
        imports = [ ../hello/configuration.nix ];
        mobile.rootfs.luks.enable = true;
      })
    ];
    additionalHelpInstructions = { device }: ''
      Build a LUKS encrypted variant of the `hello` example:

       $ nix-build examples/hello-encrypted --argstr device ${device} -A outputs.default

      The generated root filesystem is encrypted with the (insecure) build-time
      passphrase `1234`. Change it on-device after the first boot.
    '';
  }
)
