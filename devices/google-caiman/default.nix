{ ... }:

{
  imports = [
    ../families/google-zumapro
  ];

  mobile.device.name = "google-caiman";
  mobile.device.identity = {
    name = "Pixel 9 Pro";
    manufacturer = "Google";
  };

  mobile.hardware.screen = {
    width = 1280;
    height = 2856;
  };

  mobile.kernel.structuredConfig = [
    (
      helpers: with helpers; {
        DRM_PANEL_GOOGLE_CAIMAN = yes;
      }
    )
  ];

  mobile.system.android.device_name = "caiman";
}
