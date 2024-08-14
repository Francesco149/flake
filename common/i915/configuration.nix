{ pkgs, lib, ... }:
{

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # not sure if need all of these but might as well
      libva
      intel-media-driver
      intel-vaapi-driver
      intel-compute-runtime # used by opencl filters for example
      vaapiVdpau
      libvdpau-va-gl

      # qsv support up to 11th gen
      vpl-gpu-rt
      intel-media-sdk
    ];
  };

  # also needed for the qsv stuff to work
  environment.sessionVariables = {
    INTEL_MEDIA_RUNTIME = "ONEVPL";
    LIBVA_DRIVER_NAME = "iHD";
    ONEVPL_SEARCH_PATH = lib.strings.makeLibraryPath (with pkgs; [ vpl-gpu-rt ]);
  };

  hardware.intel-gpu-tools.enable = true; # intel_gpu_top monitor

  boot.kernelParams = [ "i915.enable_guc=3" ]; # enable offloading some tasks to the hw encoder

}
