{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../common/nvidia/configuration.nix
    ../../common/desktop/configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    blender
    gimp
    tenacity

    # photo editors I want to try
    darktable

    # NLE video editors I want to try (haven't picked one yet)
    flowblade
    kdenlive
    openshot-qt
    olive-editor
    pitivi
    shotcut

    avidemux # for quick cuts
    photini # exif metadata editor
  ];

  system.stateVersion = "23.05";
}
