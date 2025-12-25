{ user, pkgs, ... }:
{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    desktopManager.gnome.enable = true;
  };

  # touchpad support (touchscreen too?)
  services.libinput.enable = true;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # qt theme
  qt.enable = true;
  qt.platformTheme = "qt5ct";

  # TODO: this doesn't seem to do anything? I had to open qt5ct and manually set Adwaita-Dark.
  #       capitalized name also didnt work
  qt.style = "adwaita-dark";

  environment.systemPackages = with pkgs; [
    adwaita-qt
    libgtop # for astra
    pciutils
    lm_sensors
  ];

  # for astra
  environment.variables = {
    GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0";
  };
}
