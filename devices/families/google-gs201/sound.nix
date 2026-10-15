# The Pixel Tablet (Tensor G2 / gs201) boards route audio through the Google AoC
# with Cirrus CS35L41 quad speaker amplifiers. The ASoC card and codec support is
# shared; the board-specific speaker-protection tuning is named per device
# (`tangorpro`) and must be supplied as firmware.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  mobile.kernel.structuredConfig = [
    (
      helpers: with helpers; {
        SND = yes;
        SOUND = yes;
        SND_SOC = yes;
        SND_SOC_GOOGLE_AOC = module;
        SND_SOC_CS35L41_SPI = module;
        SND_SOC_CS35L41_I2C = module;
      }
    )
  ];
}
