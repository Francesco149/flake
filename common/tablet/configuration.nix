{ config, pkgs, ... }:
{
  environment.systemPackages = [
    config.boot.kernelPackages.digimend
  ];

  services.xserver = {
    modules = [ pkgs.xf86_input_wacom ];
    wacom.enable = true;
    digimend.enable = true;
  };
}
