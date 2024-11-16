{ ... }:
{
  imports = [
    ../../common/desktop/home.nix
  ];

    settings."org/gnome/shell".favorite-apps = [
      "firefox.desktop"
      "xterm.desktop"
      "org.gnome.Nautilus.desktop"
      "flowblade.desktop"
      "org.gnome.TextEditor.desktop"
    ];

  home.stateVersion = "24.05";
}
