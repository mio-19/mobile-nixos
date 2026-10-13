{ ... }:

{
  imports = [
    ../families/google-zumapro
  ];

  mobile.device.name = "google-komodo";
  mobile.device.identity = {
    name = "Pixel 9 Pro XL";
    manufacturer = "Google";
  };

  mobile.hardware.screen = {
    width = 1344;
    height = 2992;
  };

  mobile.system.android.device_name = "komodo";
}
