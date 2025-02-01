{ config, pkgs, ... }:
{
  services.xserver = {
    modules = [ pkgs.xf86_input_wacom ];
    wacom.enable = true;
  };
}
