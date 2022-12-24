{ config, ... }:
let

in with config; {

  imports = [
    ../common/desktop/home.nix
  ];

  # intel hd 4600's max pixel rate caps out at 120hz
  programs.autorandr.profiles."single-monitor".config.HDMI-A-0.rate="120.0";

  home.stateVersion = "22.11";

}
