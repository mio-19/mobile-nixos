{ ... }:

{
  imports = [
    ../families/google-gs201
  ];

  mobile.device.name = "google-tangorpro";
  mobile.device.identity = {
    name = "Pixel Tablet";
    manufacturer = "Google";
  };

  mobile.hardware.screen = {
    width = 2560;
    height = 1600;
  };

  mobile.system.android.device_name = "tangorpro";
}
