{ config, pkgs, ... }:

with config; {

  imports = [
    ../common/vim/home.nix
  ];

  home.packages = with pkgs; [
    wslu
    wsl-open
    youtube-dl
    yt-dlp
    aria2
  ];

  xdg.configFile = {
    "yt-dlp/config".source = ./yt-dlp/config;
    "youtube-dl/config".source = ./youtube-dl/config;
  };

}
