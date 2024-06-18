{ config, pkgs, lib, user, ... }:

let
  authorizedKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpNgs8JFiW2okM8bWoQXkXD6y3x1LONA3hNQbUmvJhMK8BP7Ajkd5avC0dhyOnHee1WCoiQfCfqN/2SVgHMDmRv2QNluciZ4scFr1IwXRxrUqRPpDid6bBIc/e7PYcFBfA2r1nfOdZTePiQcQAcb0yhblqtsg9aOgl+JwqK4GvoQgwriB3Hp6PrezRYBcQjjLbcrU8U1vqKCljhL/cYy5qj5ybJ4hRYcsuZoiQxjtomlrsmibVcTJZVnwPL3DVhCcNrPYABstVgLZfLSttCQCdB2VvGJOx5r6gaB8bkgHsqgERyZza4hBYsMPLSuzxrxgEH+AZzTBGIZiWD0WgY+81 loli@void"
  ];

  custom-obs = with pkgs;
    (wrapOBS {
      plugins = with obs-studio-plugins; [
        obs-gstreamer
        obs-move-transition
        obs-multi-rtmp
        obs-source-switcher
        obs-teleport
      ];
    });

in {
  imports = [
    ./hardware-configuration.nix
    ../common/nix.nix
  ];

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
      carla
      barrier
      custom-obs
    ]);
    openssh.authorizedKeys.keys = authorizedKeys;
  };

  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      22 # ssh
      24800 # barriers
    ];
    allowedUDPPorts = [
      9999 # teleport discovery
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
    displayManager.gdm.wayland = false; # barrier doesn't fully support wayland
    desktopManager.gnome.enable = true;
    xkb.layout = "us";
    xkb.variant = "";
  };

  # touchpad support (touchscreen too?)
  services.libinput.enable = true;

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

  # enables n100 hw encoding
  # TODO: check if all of these things are necessary

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapi-intel-hybrid
      intel-media-sdk
      vpl-gpu-rt
      intel-compute-runtime
    ];
  };

  environment.sessionVariables = {
    INTEL_MEDIA_RUNTIME= "ONEVPL";
    LIBVA_DRIVER_NAME = "iHD";
    ONEVPL_SEARCH_PATH = lib.strings.makeLibraryPath (with pkgs; [vpl-gpu-rt]);
  };

  # config files

  environment.etc = {
    "barrier.conf".source = ../barrier/barrier.conf;
    "secrets/barrier/SSL/Fingerprints/TrustedClients.txt".source = ../barrier/TrustedClients.txt;
  };

  # services

  systemd.user.services.barriers = {
    enable = true;
    description = "Barrier Server daemon";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    # TODO: don't repeat barrier dir, make it a let
    serviceConfig.ExecStart =
      toString ([ "${pkgs.barrier}/bin/barriers" "-f" "--profile-dir" "/etc/secrets/barrier/" ]);
  };

  systemd.user.services.startup-apps = {
    enable = true;
    description = "Various custom start-up apps";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      RemainAfterExit = "yes";
      Type = "oneshot";
    };

    script = ''
      "${custom-obs}/bin/obs" &
      "${pkgs.carla}/bin/carla" "/home/${user}/stream-linux.carxp" &
      "${pkgs.carla}/bin/firefox" &
    '';
  };

  # secrets

  # by default, agenix does not look in your home dir for keys
  age.identityPaths = [
    "/root/.ssh/id_ed25519"
  ];

  # agenix secrets are owned by root and symlinked from /run/agenix.d .
  # so to have user-owned secrets I have to disable symlinking and make sure the ownership is correct
  # TODO: don't copypaste these helpers everywhere
  age.secrets = let

    secretPath = path: "/etc/secrets/${path}";

    mkSecret = { file, path }: {
      inherit file;
      path = secretPath path;
      symlink = false;
    };

  in {

    barriers-private-key = mkSecret {
      file = ../secrets/barrier/Barrier.pem.age;
      path = "barrier/SSL/Barrier.pem";
    } // {
      owner = "loli"; # TODO: barrier user?
    };

  };

  system.stateVersion = "23.05";

}
