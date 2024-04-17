# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, user, ... }:

let
  authorizedKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpNgs8JFiW2okM8bWoQXkXD6y3x1LONA3hNQbUmvJhMK8BP7Ajkd5avC0dhyOnHee1WCoiQfCfqN/2SVgHMDmRv2QNluciZ4scFr1IwXRxrUqRPpDid6bBIc/e7PYcFBfA2r1nfOdZTePiQcQAcb0yhblqtsg9aOgl+JwqK4GvoQgwriB3Hp6PrezRYBcQjjLbcrU8U1vqKCljhL/cYy5qj5ybJ4hRYcsuZoiQxjtomlrsmibVcTJZVnwPL3DVhCcNrPYABstVgLZfLSttCQCdB2VvGJOx5r6gaB8bkgHsqgERyZza4hBYsMPLSuzxrxgEH+AZzTBGIZiWD0WgY+81 loli@void"
  ];

in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "streampc";
  networking.networkmanager.enable = true;

  # ssh mainly to be able to build the system from tanuki or other pc's
  # don't wanna set up all the dev tools here when it's mainly for streaming
  services.openssh.enable = true;

  users.users."${user}" = {
    isNormalUser = true;
    description = "${user}";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = (with pkgs; [
      firefox
      qpwgraph

      # obs sdk version provided by official website changes so we have to rehash it
      # https://github.com/NixOS/nixpkgs/issues/219578#issuecomment-1586322972
      (wrapOBS {
        plugins = with obs-studio-plugins; [
          wlrobs
          obs-gstreamer
          obs-move-transition
          obs-multi-rtmp
        ] ++ (lib.optionals pkgs.config.allowUnfree [ (obs-ndi.override {
          ndi = ndi.overrideAttrs (attrs: rec {
            version = "5.6.0";

            src = fetchurl {
              name = "${attrs.pname}-${version}.tar.gz";
              url = "https://downloads.ndi.tv/SDK/NDI_SDK_Linux/Install_NDI_SDK_v5_Linux.tar.gz";
              hash = "sha256-flxUaT1q7mtvHW1J9I1O/9coGr0hbZ/2Ab4tVa8S9/U=";
            };

            installPhase = lib.concatStringsSep "\n" (lib.filter (line: !(lib.hasPrefix "mv logos " line)) (lib.splitString "\n" attrs.installPhase));
          });
        }) ]);
      })
    ]);
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      22 # ssh
    ];
  };

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    xkb.layout = "us";
    xkb.variant = "";

    # touchpad support (touchscreen too?)
    libinput.enable = true;
  };

  sound.enable = false;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "${user}";
  };

  # qt theme
  qt.enable = true;
  qt.platformTheme = "qt5ct";

  # TODO: this doesn't seem to do anything? I had to open qt5ct and manually set Adwaita-Dark.
  #       capitalized name also didnt work
  qt.style = "adwaita-dark";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  environment.systemPackages = with pkgs; [
    vim
    adwaita-qt
  ];

  # workarounds for n100 hw encoding
  # https://github.com/RyanGibb/nixos/commit/55aca5b360f734f8db8d426c2a6b803e164cf531

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapi-intel-hybrid
      intel-media-sdk
      oneVPL-intel-gpu
      intel-compute-runtime
    ];
  };

  environment.sessionVariables = {
    INTEL_MEDIA_RUNTIME= "ONEVPL";
    LIBVA_DRIVER_NAME = "iHD";
    ONEVPL_SEARCH_PATH = lib.strings.makeLibraryPath (with pkgs; [oneVPL-intel-gpu]);
  };

  system.stateVersion = "23.05";

}
