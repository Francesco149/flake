{ config, pkgs, ... }:
with config; {

  xresources.properties = {
    "*xterm*faceName" = "PxPlus IBM VGA8";
    "*xterm*faceNameDoublesize" = "Unifont";
    "*xterm*faceSize" = 12;
    "*xterm*allowBoldFonts" = false;
    "*xterm*background" = "black";
    "*xterm*foreground" = "grey";
    "*xterm*reverseVideo" = false;
    "*xterm*termName" = "xterm-256color";
    "*xterm*VT100.Translations" = ''#override \
      Shift <Key>Insert: insert-selection(CLIPBOARD) \n\
      Ctrl Shift <Key>V: insert-selection(CLIPBOARD) \n\
      Ctrl Shift <Key>C: copy-selection(CLIPBOARD)
    '';
  };

  home.packages = with pkgs; [
    pxplus-ibm-vga8-bin
  ];

}
