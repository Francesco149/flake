{ config, pkgs, user, ... }:

with config; {

  # TODO: why is this needed? I already have it in configuration.nix
  # without it, I get 'A corresponding Nix package must be specified via `nix.package`'
  nix.package = pkgs.nixFlakes;

  imports = [
    ../../common/vim/home.nix
  ];

  home.packages = with pkgs; [
    wslu
    wsl-open
    youtube-dl
    yt-dlp
    aria2
    ffmpeg
  ];

  xdg.configFile = {
    "yt-dlp/config".source = ../../common/desktop/yt-dlp/config;
    "youtube-dl/config".source = ../../common/desktop/youtube-dl/config;
  };

  home.username = "${user}";
  home.homeDirectory = "/home/${user}";

  home.stateVersion = "22.05";

}
