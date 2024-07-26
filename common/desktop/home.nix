{ config, pkgs, user, configName, lib, ... }:

let
  consts = import ../consts.nix;
  themeName = "Adwaita-dark";

in
with config; {

  imports = [
    ../vim/home.nix
    ../gnome/home.nix
    ./gnome/home.nix
    ../xterm/home.nix
  ];

  home.username = "${user}";
  home.homeDirectory = "/home/${user}";

  home.packages = (with pkgs; [

    curl
    wget
    htop
    btop
    tokei
    git
    ffmpeg
    yt-dlp
    aria
    nnn
    picotts
    gh
    bind.dnsutils # dig

    xclip # required for pass show -c, also useful in general
    mpv
    libnotify # notify-send

    unifont
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    noto-fonts-extra

    xkcdpass
    p7zip
    internetarchive

    (pkgs.writeShellScriptBin "speak" ''
      file=$(mktemp /tmp/XXXXXXXXXX.wav)
      pico2wave -w "$file" "$@"
      mpv --no-config "$file"
      rm "$file"
    '')

    (pkgs.writeShellScriptBin "countdown" ''
      start="$(( $(date '+%s') + $1))"
      while [ $start -ge $(date +%s) ]; do
          time="$(( $start - $(date +%s) ))"
          printf '%s\r' "$(date -u -d "@$time" +%H:%M:%S)"
          sleep 0.1
      done
      msg="''${2:-countdown finished}"
      notify-send "$msg"
      speak "$msg"
    '')

    font-awesome
    fira-mono
    roboto

    v4l-utils
    gh2md
    gist
    autorandr # save and detect xrandr configurations automatically
    fusee-launcher
    pass

    seahorse # to manage gnome keyring for apps that want it
    transmission_4-gtk

    dmenu
    maim
    firefox
    telegram-desktop
    chatterino2
    obs-studio
    simplescreenrecorder
    screenkey
    gimp
    blender
    tenacity
    tor-browser-bundle-bin
    quickemu
    qemu_kvm
    shotcut
    gnumeric
    abiword
    sxiv
    komikku
    scrcpy
    armcord

    (pkgs.writeShellScriptBin "cam" ''
      mpv --profile=low-latency --untimed $(ls /dev/video* | dmenu)
    '')

    (pkgs.writeShellScriptBin "rerandr" ''
      autorandr --change --force
      notify-send "autorandr config: $(autorandr --current)"
    '')

    (pkgs.writeShellScriptBin "shot" ''
      maim -s --format png /dev/stdout | xclip -selection clipboard -t image/png -i
    '')

  ]);

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      xb = "pushd ~/flake && nixos-rebuild switch --use-remote-sudo --build-host ${consts.machines.dekai.ip} --flake .#${configName}; popd";
      xt = "pushd ~/flake && nixos-rebuild test --use-remote-sudo --build-host ${consts.machines.dekai.ip} --flake .#${configName}; popd";
      xlb = "pushd ~/flake && nixos-rebuild switch --use-remote-sudo --flake .#${configName}; popd";
      xlt = "pushd ~/flake && nixos-rebuild test --use-remote-sudo --flake .#${configName}; popd";
      xu = "pushd ~/flake && nix flake update; popd";
      xub = "xu && xb";
      xq = "nix search nixpkgs";
      yt-date = "yt-dlp --skip-download --get-filename --output '%(upload_date)s'";
    };
    bashrcExtra = ''
      set -o vi
    '';
  };

  programs.alacritty.enable = true; # backup terminal just in case

  xdg.dataFile = {
    # TODO: for some reason it's not able to mkdir this so I have to manually create it
    "barrier/SSL/Fingerprints/TrustedServers.txt".source = ./barrier/TrustedServers.txt;
    "wallpaper.png".source = ./wallpaper.png;
    "chatterino/Settings/window-layout.json".source = ./chatterino/window-layout.json;
  };

  xdg.configFile = {
    "git/config".source = ./git/gitconfig;
  };

  gtk.enable = true;
  gtk.theme.name = themeName;
  gtk.theme.package = pkgs.gnome-themes-extra;
  gtk.iconTheme.name = "Paper";
  gtk.iconTheme.package = pkgs.paper-icon-theme;

  xdg.configFile = {
    "yt-dlp/config".source = ./yt-dlp/config;
    "mpv/scripts/copyTime.lua".source = ./mpv/scripts/copyTime.lua;
  };

  services.barrier.client = {
    enable = true;
    server = consts.machines.streampc.ip;
    enableDragDrop = true;
  };

  # TODO: not sure if these settings are necessary with gnome. maybe they're enabled by default
  programs.gpg = {
    enable = true;
    homedir = "${xdg.dataHome}/gnupg";
    settings.use-agent = true;
  };

  home.file."${programs.gpg.homedir}/.keep".text = "";

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  services.gnome-keyring.enable = true;
}
