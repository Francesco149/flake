{ user, ... }:

{

  # unused at the moment, but previously tested.
  # if I ever need to do GPU passthrough again, this is some of the setup

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

  boot.kernelParams = [
    "amd_iommu=on"
    "intel_iommu=on"
    "iommu=pt"
    "rd.driver.pre=vfio-pci"
    "pcie_acs_override=downstream,multifunction"
  ];

}
