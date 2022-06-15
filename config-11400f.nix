{ pkgs, user, ... }:

{
  imports = [
    ./hardware-11400f.nix
    ./configuration.nix
  ];

  networking.hostName = "nixos";
  networking.hostId = "8556b001";
  networking.interfaces.br0.ipv4.addresses = [{
    address = "192.168.1.9";
    prefixLength = 24;
  }];
  networking.dhcpcd.enable = false;

  boot.supportedFilesystems =  [ "zfs" ];
  boot.zfs.devNodes = "/dev/";
  boot.kernelParams = [
    "amd_iommu=on"
    "intel_iommu=on"
    "iommu=pt"
    "rd.driver.pre=vfio-pci"
    "pcie_acs_override=downstream,multifunction"
    "usbhid.kbpoll=1"
    "usbhid.mousepoll=1"
    "usbhid.jspoll=1"
    "noibrs"
    "noibpb"
    "nopti"
    "nospectre_v2"
    "nospectre_v1"
    "l1tf=off"
    "nospec_store_bypass_disable"
    "no_stf_barrier"
    "mds=off"
    "mitigations=off"
    "amdgpu.ppfeaturemask=0xffffffff"
    "zfs.zfs_arc_max=2147483648"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.zfs.trim.enable = true;
  services.nfs.server.enable = true;

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

  # bridge + tap setup for qemu
  networking.bridges.br0 = {
    rstp = false;
    interfaces = [ "eth0" ];
  };

  networking.interfaces.br0.virtual = true;

  environment.etc."qemu/bridge.conf".text = "allow br0";

  networking.interfaces.tap0 = {
    virtualOwner = "${user}";
    virtual = true;
    virtualType = "tap";
    useDHCP = true;
  };

  networking.defaultGateway = {
    interface = "br0";
    address = "192.168.1.1";
  };
}
