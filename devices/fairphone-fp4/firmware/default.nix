{
  lib,
  fetchFromGitHub,
  runCommand,
}:

let
  src = fetchFromGitHub {
    owner = "FairBlobs";
    repo = "FP4-firmware";
    rev = "222756885ff5eb24ee89684ef8cfe860a45a54ec";
    hash = "sha256-ANbMpRurzYhkeXiqP0JMWByZG0Q0qLiywbX/mX3c890=";
  };
in
runCommand "fairphone-fp4-firmware"
  {
    inherit src;
    meta.license = lib.licenses.unfreeRedistributableFirmware;
  }
  ''
    firmware="$out/lib/firmware"
    soc="$firmware/qcom/sm7225/fairphone4"
    mkdir -p "$soc" "$firmware/qcom" "$firmware/qca" \
      "$firmware/postmarketos" "$out/share/hexagon"

    for name in adsp cdsp modem venus; do
      cp "$src"/"$name".b* "$soc/"
      cp "$src/$name.mdt" "$soc/$name.mdt"
      ln -s "$name.mdt" "$soc/$name.mbn"
    done

    cp "$src"/adspr.jsn "$src"/adsps.jsn "$src"/adspua.jsn \
      "$src"/cdspr.jsn "$src"/modemr.jsn "$src"/modemuw.jsn "$soc/"
    cp -r "$src/modem_pr" "$soc/"

    cp "$src"/a615_zap.b* "$soc/"
    cp "$src/a615_zap.mdt" "$soc/a615_zap.mdt"
    ln -s a615_zap.mdt "$soc/a615_zap.mbn"
    cp "$src/a619_gmu.bin" "$src/a630_sqe.fw" "$firmware/qcom/"

    for file in "$src"/lagoon_ipa_fws.b* "$src/lagoon_ipa_fws.mdt"; do
      suffix="''${file##*.}"
      cp "$file" "$soc/ipa_fws.$suffix"
    done
    ln -s ipa_fws.mdt "$soc/ipa_fws.mbn"
    cp "$src/wlanmdsp.mbn" "$soc/"

    cp "$src/apbtfw11.tlv" "$src/apnv11.bin" "$firmware/qca/"
    cp "$src"/aw882xx_*.bin "$firmware/postmarketos/"
    cp -r "$src/hexagonfs/"* "$out/share/hexagon/"
  ''
