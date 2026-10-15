{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      sc7280-alsa-ucm = self.callPackage (
        { runCommand, fetchFromGitHub }:

        runCommand "sc7280-alsa-ucm" {
          src = fetchFromGitHub {
            owner = "sc7280-mainline";
            repo = "alsa-ucm-conf";
            rev = "c6fdb24805b75b47a0dc415ba199563b20fad42d";
            sha256 = "sha256-zsCRqgrzq3V+ICPrpMEthGhJecpGKoM6MD0hZmZqS6Q=";
          };
        } ''
          mkdir -p $out/share/
          ln -s $src $out/share/alsa
        ''
      ) {};
    })
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="sound", KERNEL=="card0", ATTR{id}=="NP1", ENV{ID_ID}="NP1"
  '';

  # Alsa UCM profiles
  mobile.quirks.audio.alsa-ucm-meld = true;
  environment.systemPackages = [
    pkgs.sc7280-alsa-ucm
  ];
}
