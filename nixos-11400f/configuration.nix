{ pkgs, user, lib, config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/desktop/configuration.nix
  ];

  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.modesetting.enable = true;

  networking = {
    hostName = "nixos";
    hostId = "8556b001";
  };

  boot.supportedFilesystems =  [ "zfs" ];
  boot.zfs.devNodes = "/dev/";
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"
    "zfs.zfs_arc_max=2147483648"
  ];

  # try to optimize power consumption
  boot.kernel.sysctl = {
    "kernel.nmi_watchdog" = 0;
    "vm.dirty_writeback_centisecs" = 6000;
    "vm.laptop_mode" = 5;
  };

  powerManagement = {
    powertop.enable = true;
    scsiLinkPolicy = "med_power_with_dipm";
  };

  # spin down disks after 21mins
  powerManagement.powerUpCommands = ''
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K3PNERFU
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K2EJP002
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K3PNE22D
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K4ES2R9F
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K6DV1X2V
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K0HP5XTS
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K3ACZK44
    ${pkgs.hdparm}/sbin/hdparm -S 252 /dev/disk/by-id/ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K2EJY0NR
  '';

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.zfs.trim.enable = true;

  services.zfs.autoScrub = {
    enable = true;
    pools = [ "rpool" ];
  };

  services.zfs.autoSnapshot = {
    enable = true;
    frequent = 96; # keep the latest x 15-minute snapshots (instead of four)
    monthly = 24;  # keep x monthly snapshot (instead of twelve)
  };

  # according to the wiki, zfs has its own scheduler and this supposedly prevent freezes
  # I haven't had any issues personally
  services.udev.extraRules = ''
  ACTION=="add|change", KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"
  '';

  system.stateVersion = "22.05";

}
