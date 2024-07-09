{ config, pkgs, lib, user, ... }:

let

  consts = import ../../common/consts.nix;
  inherit (consts.ssh) authorizedKeys;

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

  custom-firefox = with pkgs;
    (pkgs.wrapFirefox
      (pkgs.firefox-unwrapped.override {
        jackSupport = true;
      })
      { });

in
{
  imports = [
    ./hardware-configuration.nix
    ../../common/nix/configuration.nix
    ../../common/locale/configuration.nix
    ../../common/gnome/configuration.nix
    ../../common/mpv/configuration.nix
    ../../common/autologin/configuration.nix
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
    extraGroups = [ "networkmanager" "wheel" "audio" "jackaudio" ];
    packages = with pkgs; [
      custom-firefox
      raysession
      git # used by raysession
      barrier
      custom-obs
      armcord

      (pkgs.writeShellScriptBin "mus" ''
        mpv --ao=jack --jack-name=mpv-music --no-video --ytdl-format=bestaudio --loop-playlist "$@"
      '')
    ];

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

  # TODO: for some reason I can't get RaySession to see the pipewire jack compatibility
  services.pipewire.jack.enable = false;
  services.jack.jackd.enable = true;

  # enables n100 hw encoding
  # TODO: check if all of these things are necessary

  hardware.graphics = {
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
    INTEL_MEDIA_RUNTIME = "ONEVPL";
    LIBVA_DRIVER_NAME = "iHD";
    ONEVPL_SEARCH_PATH = lib.strings.makeLibraryPath (with pkgs; [ vpl-gpu-rt ]);
  };

  # barrier server

  environment.etc = {
    "barrier.conf".source = ../../common/barrier/barrier.conf;
    "secrets/barrier/SSL/Fingerprints/TrustedClients.txt".source = ../../common/barrier/TrustedClients.txt;
  };

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

  # secrets

  # by default, agenix does not look in your home dir for keys
  age.identityPaths = [
    "/root/.ssh/id_ed25519"
  ];

  # agenix secrets are owned by root and symlinked from /run/agenix.d .
  # so to have user-owned secrets I have to disable symlinking and make sure the ownership is correct
  # TODO: don't copypaste these helpers everywhere
  age.secrets =
    let

      secretPath = path: "/etc/secrets/${path}";

      mkSecret = { file, path }: {
        inherit file;
        path = secretPath path;
        symlink = false;
      };

    in
    {

      barriers-private-key = mkSecret
        {
          file = ../../secrets/barrier/Barrier.pem.age;
          path = "barrier/SSL/Barrier.pem";
        } // {
        owner = "loli"; # TODO: barrier user?
      };

    };

  system.stateVersion = "23.05";

}
