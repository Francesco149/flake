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
    act # type act to run github actions
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

    font-awesome
    fira-mono
    roboto

    v4l-utils
    gh2md
    gist
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
    tor-browser-bundle-bin
    gnumeric
    abiword
    sxiv
    komikku
    scrcpy
    legcord

    # cross flash a st-link device to j-link and then program it with jlink
    stlink-tool
    segger-jlink

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
      xi = "nix-shell -p";
      yt-date = "yt-dlp --skip-download --get-filename --output '%(upload_date)s'";
      yt-playlist = "yt-dlp --flat-playlist -i --print-to-file url"; # yt-playlist links.txt url
    };
    bashrcExtra = ''
      set -o vi
    '';
  };

  programs.alacritty.enable = true; # backup terminal just in case

  gtk.enable = true;
  gtk.theme.name = themeName;
  gtk.theme.package = pkgs.gnome-themes-extra;
  gtk.iconTheme.name = "Paper";
  gtk.iconTheme.package = pkgs.paper-icon-theme;

  xdg.configFile = {
    "yt-dlp/config".source = ./yt-dlp/config;
    "mpv/scripts/copyTime.lua".source = ./mpv/scripts/copyTime.lua;
    "git/config".source = ./git/gitconfig;
  };

  xdg.dataFile = {
    "wallpaper.png".source = ./wallpaper.png;
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
