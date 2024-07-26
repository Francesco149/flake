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

  environment.systemPackages = with pkgs; [
    pulseaudio # pactl to control pipewire
  ];

  users.users."${user}" = {
    isNormalUser = true;
    description = "${user}";
    extraGroups = [ "networkmanager" "wheel" "audio" ];
    packages = with pkgs; [
      firefox
      carla
      barrier
      custom-obs
      armcord
      chatterino2

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

  # loopback device that I use to send music to my visualizer in the browser (appears as a mic)
  services.pipewire.extraConfig.pipewire = {

    "10-loopback"."context.modules" =
      let
        sinkName = x: (builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower x)) + "_sink";
        loopback = x: {
          name = "libpipewire-module-loopback";
          args = {
            "audio.position" = [ "FL" "FR" ];
            "capture.props" = {
              "media.class" = "Audio/Sink";
              "node.name" = sinkName x;
              "node.description" = "${x} Sink (In)";
            };

            # the loopback device already has a built in output.
            # this is more useful if you need to hardwire it to a device with node.target

            #"playback.props" = {
            #  "media.class" = "Audio/Source";
            #  "node.name" = (sinkName x) + "_out";
            #  "node.description" = "${x} Sink (Out)";
            #};
          };
        };
      in
      [
        (loopback "Music")
        (loopback "Quiet Game Compressed")
        (loopback "Other Audio Vod")
        (loopback "Other Audio NoVod")
        (loopback "Compressed Other Audio Vod")
        (loopback "Compressed Other Audio NoVod")
      ];

    # this makes the jack monitors properly restore in carla
    "01-jack-monitor"."jack.properties"."jack.merge-monitor" = true;
  };

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
        owner = "${user}";
        group = "users";
      };

    in
    {

      barriers-private-key = mkSecret {
        file = ../../secrets/barrier/Barrier.pem.age;
        path = "barrier/SSL/Barrier.pem";
      };

      chatterino-settings = mkSecret {
        file = ../../secrets/chatterino/overlay.json.age;
        path = "/home/${user}/.local/share/chatterino/Settings/settings.json";
      };

    };

  system.stateVersion = "23.05";

}
