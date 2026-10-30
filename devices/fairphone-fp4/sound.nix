{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      fairphone-fp4-alsa-ucm = final.callPackage (
        { runCommand, fetchFromGitHub }:

        runCommand "fairphone-fp4-alsa-ucm"
          {
            src = fetchFromGitHub {
              owner = "sm6350-mainline";
              repo = "alsa-ucm-conf";
              rev = "4618b054b80f32bd8f0deeaf93e37fbfde256251";
              hash = "sha256-sg+AGETNde0Dc9xvL+LY6m0STlKQNObl4PxpD5kn+Eo=";
            };
          }
          ''
            ucm=$out/share/alsa/ucm2
            mkdir -p "$ucm/Fairphone/fp4" "$ucm/conf.d/sm7225"
            cp "$src/ucm2/Fairphone/fp4/HiFi.conf" \
              "$src/ucm2/Fairphone/fp4/fp4.conf" "$ucm/Fairphone/fp4/"
            cp "$src/ucm2/conf.d/sm7225/Fairphone 4.conf" \
              "$ucm/conf.d/sm7225/"
          ''
      ) { };
    })
  ];
}
