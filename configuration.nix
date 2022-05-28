{ config, pkgs, user, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
  };

  nixpkgs.overlays = [
    (self: super: with super; {

      self.maintainers = super.maintainers.override {
        lolisamurai = {
          email = "lolisamurai@animegirls.xyz";
          github = "Francesco149";
          githubId = 973793;
          name = "Francesco Noferi";
        };
      };

      chatterino7 = chatterino2.overrideAttrs (old: rec {
        pname = "chatterino7";
        version = "7.3.5";
        src = fetchFromGitHub {
          owner = "SevenTV";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-lFzwKaq44vvkbVNHIe0Tu9ZFXUUDlWVlNXI40kb1GEM=";
          fetchSubmodules = true;
        };
        # required for 7tv emotes to be visible
        # TODO: is this robust? in an actual package definition we wouldn't have qt5,
        #       but just self.qtimageformats doesn't work. what if qt version changes
        buildInputs = old.buildInputs ++ [ self.qt5.qtimageformats ];
        meta.description = old.meta.description + ", with 7tv emotes";
        meta.homepage = "https://github.com/SevenTV/chatterino7";
        meta.changelog = "https://github.com/SevenTV/chatterino7/releases";
      });

      pxplus-ibm-vga8-bin = let
        version = "2020-09-15";
        pname = "pxplus-ibm-vga8-bin";
      in fetchurl {
        name = "${pname}-${version}";
        url = "https://github.com/pocketfood/Fontpkg-PxPlus_IBM_VGA8/raw/bf08976574bbaf4c9efb208025c71109a07e259f/PxPlus_IBM_VGA8.ttf";
        sha256 = "sha256-T6is06C/1w02D9+Y3bQplLSgBWunTZfYfV0XHQJh5NE=";
        downloadToTemp = true;
        recursiveHash = true; # ttf fetches in nixpkgs seem to use this, not sure if it's specific to ttf hashing
        postFetch = ''
          install -Dm 444 "$downloadedFile" "$out/share/fonts/truetype/${pname}.ttf"
        '';

        meta = with lib; {
          description = "monospace pixel font";
          homepage = "https://int10h.org/oldschool-pc-fonts/fontlist/font?ibm_vga_8x16";
          license = with licenses; [ cc-by-sa-40 ];
          platforms = platforms.all;
          maintainers = with maintainers; [ lolisamurai ];
        };
      };

    })
  ];

  boot.supportedFilesystems = [ "zfs" ];
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
    "zfs.zfs_arc_max=2147483648"
    "amdgpu.ppfeaturemask=0xffffffff"
  ];

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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "nixos";
    hostId = "8556b001";
    domain = "localhost";
    dhcpcd.enable = false;
    usePredictableInterfaceNames = false;
    nameservers = [ "8.8.8.8" ];
    resolvconf.enable = false;
  };

  # bridge + tap setup for qemu
  networking.bridges.br0 = {
    rstp = false;
    interfaces = [ "eth0" ];
  };

  networking.interfaces.br0 = {
    virtual = true;
    ipv4.addresses = [{
      address = "192.168.1.9";
      prefixLength = 24;
    }];
  };

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

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.xserver = {
    enable = true;
    layout = "us";
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = false;
    desktopManager.gnome.enable = true;
    displayManager.autoLogin.enable = true;
    displayManager.autoLogin.user = "${user}";
  };

  # workaround for race condition in autologin
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # don't wanna get suck in emergency mode over benign errors
  systemd.enableEmergencyMode = false;

  services.xserver.libinput = {
    enable = true;
    mouse.accelProfile = "flat";
    touchpad.accelProfile = "flat";
  };

  services.xserver.xkbOptions = "caps:escape";

  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh.enable = true;

  system.stateVersion = "22.05";
}
