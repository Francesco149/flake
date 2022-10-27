{ pkgs, user, ... }:

{
  networking = {
    domain = "localhost";
    usePredictableInterfaceNames = false;
    nameservers = [ "8.8.8.8" ];
    resolvconf.enable = false;
  };

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # bluetooth
  hardware.bluetooth = {
    enable = true;

    # TODO: is this still doing anything?
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  services.blueman.enable = true;

  # TODO: check if this is actually required for bluetooth
  hardware.pulseaudio.package = pkgs.pulseaudioFull;

  services.gvfs.enable = true; # for nautilus
  services.udisks2.enable = true; # to mount removable devices more easily

  # don't wanna get suck in emergency mode over benign errors
  systemd.enableEmergencyMode = false;

  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
