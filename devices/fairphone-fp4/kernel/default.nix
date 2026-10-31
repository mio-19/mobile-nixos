{
  mobile-nixos,
  fetchurl,
  ...
}:

mobile-nixos.kernel-builder {
  version = "7.2.0";
  configfile = ./config.aarch64;

  src = fetchurl {
    url = "https://github.com/sm6350-mainline/linux/archive/refs/tags/v7.2.0-sm6350.tar.gz";
    hash = "sha512-Ikc3eyYOukijvChA/opVzsgsORlJtZ3IMJOvJ83sZiRe+488f8ThBfqLHaCQM1ysrYvMbPoSjdJf97RzKX8lMA==";
  };

  isModular = true;
  isCompressed = "gz";
}
