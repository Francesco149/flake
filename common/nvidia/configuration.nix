{ config, ... }:
{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false; # experimental, might fix sleep issues
    powerManagement.finegrained = false; # experimental, saves power when gpu is not in use
    open = false; # open source kernel driver (experimental, unstable)
    nvidiaSettings = true; # `nvidia-settings`
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
}

