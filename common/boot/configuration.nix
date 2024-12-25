{ ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max"; # hdmi switch is happier if we dont switch res during boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];
}
