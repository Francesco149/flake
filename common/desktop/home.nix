{ config, pkgs, user, configName, lib, ... }:

let
  pythonPackages = pkgs.python39Packages; # adjust python version here as needed

  themeName = "Adwaita-dark";

  # some programs don't use the gtk file picker by default.
  # tricking them into thinking I'm running gnome seems to work
  fix-file-picker = binary: pkgs.writeShellScriptBin (baseNameOf binary) ''
    exec env XDG_CURRENT_DESKTOP=gnome ${binary} "$@"
  '';

  # some gnome applications don't follow gtk theme by default
  fix-theme = binary: pkgs.writeShellScriptBin (baseNameOf binary) ''
    exec env GTK_THEME=${themeName} ${binary} "$@"
  '';

  consts = import ../consts.nix;

in
with config; {

  imports = [
    ../vim/home.nix
  ];

  home.username = "${user}";
  home.homeDirectory = "/home/${user}";

  # temp fix until https://github.com/LnL7/nix-darwin/pull/552 is merged
  manual.manpages.enable = false;

  # thanks to nix's import system, the machine-specific config is merged with this base config.
  # so, for example I can define home.packages again in a machine-specific config and it will concatenate
  # it to this list automatically in the import process

  home.packages = (with pkgs; [

    curl
    wget
    htop
    btop
    tokei
    git
    ffmpeg
    yt-dlp
    youtube-dl
    aria
    nnn
    picotts
    gh

    xclip # required for pass show -c, also useful in general
    mpv
    libnotify # notify-send

    man-pages
    man-pages-posix

    pxplus-ibm-vga8-bin
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
    #steam-run # used to run non-nixos executables
    # TODO: find non-proprietary alternative

    nitrogen
    gcr # required for pinentry-gnome?
    polkit_gnome
    (fix-theme "${pkgs.gnome.nautilus}/bin/nautilus")
    gnome.seahorse # to manage gnome keyring for apps that want it
    transmission-gtk

    dmenu
    maim
    firefox
    (fix-file-picker "${pkgs.tdesktop}/bin/telegram-desktop")
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
    (fix-file-picker "${pkgs.shotcut}/bin/shotcut")
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

  xsession = {
    enable = true;

    windowManager.command = ''
      ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
      nitrogen --set-tiled ${xdg.dataHome}/wallpaper.png
      chatterino &
      firefox &
      telegram-desktop &
      exec ${pkgs.cwm}/bin/cwm -c ${xdg.configHome}/cwm/cwmrc
    '';
  };

  xsession.scriptPath = ".hm-xsession";

  xdg.configFile = {
    "cwm/cwmrc".source = ./cwm/cwmrc;
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

  services.dunst.enable = true;

  services.dunst.settings = {

    global = {
      font = "Noto Sans Bold";
      background = "#000";
      foreground = "#bebebe";
      corner_radius = 20;
      frame_color = "#bebebe";
      frame_width = 2;
      padding = 16;
      horizontal_padding = 16;
    };

    urgency_low.timeout = 5;
    urgency_normal.timeout = 10;
    urgency_critical.timeout = 0;

    urgency_critical = {
      foreground = "#fff";
      background = "#900000";
      frame_color = "#ff0000";
    };

    fullscreen_show_critical = {
      msg_urgency = "critical";
      fullscreen = "show";
    };

  };

  gtk.enable = true;
  gtk.theme.name = themeName;
  gtk.theme.package = pkgs.gnome.gnome-themes-extra;
  gtk.iconTheme.name = "Paper";
  gtk.iconTheme.package = pkgs.paper-icon-theme;

  xdg.configFile = {
    "yt-dlp/config".source = ./yt-dlp/config;
    "youtube-dl/config".source = ./youtube-dl/config;
    "mpv/scripts/copyTime.lua".source = ./mpv/scripts/copyTime.lua;
  };

  services.barrier.client = {
    enable = true;
    server = consts.machines.streampc.ip;
    enableDragDrop = true;
  };

  services.blueman-applet.enable = true;

  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      pulseSupport = true;
    };
    script = ''
      rerandr
      polybar top --reload &
    '';
  };

  services.polybar.config = {

    colors = {
      underline-1 = "#c792ea";
      foreground-alt = "#555";
      secondary = "#e60053";
    };

    "bar/top" = {
      width = "100%";
      height = "32px";
      radius = 0;
      modules-center = "date";
      modules-left = "cpu temperature memory";
      modules-right = "filesystem volume";
      padding-right = 2;
      padding-left = 2;
      separator = "   ";
      tray-position = "right"; # enables tray on right side (disabled otherwise)
      cursor-click = "pointer"; # instead of the X
      cursor-scroll = "ns-resize"; # instead of the X
      tray-maxsize = 28;
      line-size = 2;
      line-color = "#f00";

      #font-0 = "Noto Sans:weight=bold";
      font-0 = "Noto Sans:weight=bold";
      font-1 = "Font Awesome";
      font-2 = "Material Icons";
      font-3 = "Fira Mono:size=8";
      # some emoji fonts need scale= otherwise they appear way too big
      #font-4 = "Noto Emoji:scale=6";
    };

    "module/volume" = {
      # the polybar module is supposed to convert things like format.volume -> format-volume.
      # this doesn't seem to work, so I have to name them like the actual polybar cfg.
      # array conversion also doesn't seem to work.
      # also, for some reason format-underline doesn't work for this volume module
      type = "internal/pulseaudio";
      format-volume = "<ramp-volume> <label-volume>";
      label-muted = "";
      label-muted-foreground = "#ff7777";
      ramp-volume-0 = "";
      ramp-volume-1 = "";
      ramp-volume-2 = "";
      ramp-volume-3 = "";
      click-right = "pavucontrol";
    };

    "module/date" = {
      type = "internal/date";
      internal = 5;
      date-alt = "%Y-%m-%d";
      time-alt = "%H:%M:%S";
      date = "%A, %d %B %Y";
      time = "%H:%M";
      label = "%date% %time%";
      format = " <label>";
      format-underline = "\${colors.underline-1}";
    };

    "module/cpu" = {
      type = "internal/cpu";
      interval = 2;
      format = "<label> <ramp-coreload>";
      format-underline = "\${colors.underline-1}";
      label = "%percentage:2%%";
      ramp-coreload-spacing = 0;
      ramp-coreload-0-foreground = "\${colors.foreground-alt}";
      ramp-coreload-0 = "▁";
      ramp-coreload-1 = "▂";
      ramp-coreload-2 = "▃";
      ramp-coreload-3 = "▄";
      ramp-coreload-4 = "▅";
      ramp-coreload-5 = "▆";
      ramp-coreload-6 = "▇";
    };

    "module/memory" = {
      type = "internal/memory";
      interval = 3;
      warn-percentage = 95;
      format = "<ramp-used> <label>";
      label = " %gb_used%/%gb_total%";
      ramp-used-0 = "▁";
      ramp-used-1 = "▂";
      ramp-used-2 = "▃";
      ramp-used-3 = "▄";
      ramp-used-4 = "▅";
      ramp-used-5 = "▆";
      ramp-used-6 = "▇";
      format-underline = "\${colors.underline-1}";
    };

    "module/temperature" = {
      type = "internal/temperature";
      thermal-zone = 0;
      warn-temperature = 60;

      format = "<label>";
      format-underline = "\${colors.underline-1}";
      format-warn = "<label-warn>";
      format-warn-underline = "\${self.format-underline}";

      label = "%temperature-c%";
      label-warn = "%temperature-c%!";
      label-warn-foreground = "\${colors.secondary}";
    };

    "module/filesystem" = {
      type = "internal/fs";
      mount-0 = "/";
      interval = 10;
      fixed-values = true;
      spacing = 4;
      warn-percentage = 75;
      label-mounted = " %mountpoint% %percentage_used%%";
      format-underline = "\${colors.underline-1}";
    };

  };

  services.parcellite = {
    enable = true;
    package = pkgs.clipit;
  };

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

  xdg.mimeApps =
    let
      firefoxDesktop = "firefox.desktop";
      associations = {
        "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
        "x-scheme-handler/http" = firefoxDesktop;
        "x-scheme-handler/https" = firefoxDesktop;
        "text/html" = firefoxDesktop;
        "application/pdf" = firefoxDesktop;
        "application/x-extension-htm" = firefoxDesktop;
        "application/x-extension-html" = firefoxDesktop;
        "application/x-extension-shtml" = firefoxDesktop;
        "application/xhtml+xml" = firefoxDesktop;
        "application/x-extension-xhtml" = firefoxDesktop;
        "application/x-extension-xht" = firefoxDesktop;
      };
    in
    {
      enable = true;
      defaultApplications = associations;
      associations.added = associations;
    };

  programs.autorandr.enable = true;
  programs.autorandr.hooks.postswitch = {
    "change-dpi" = ''
      echo "Xft.dpi: 95" | ${pkgs.xorg.xrdb}/bin/xrdb -merge
    '';
    "refresh-polybar" = ''
      systemctl --user restart polybar
    '';
  };
  programs.autorandr.profiles =
    let
      miniMonLeft = "00ffffffffffff001ee456010000000009200103807341780bcf74a75546982410494b2108008180950090400101a940b300614001019c84809470383c403020e50458c1100000185536809470383c403020e50458c110000000000000fc0041525a4f50410a202020202020000000fd0030901faa24000a202020202020011502031cc3420400230907078301000068030c001000884800e305c0004037809470383c403020e50458c110000018816e809470383c403020e50458c1100000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004f";
      miniMonMid = "00ffffffffffff001ee456010000000009200103807341780bcf74a75546982410494b2108008180950090400101a940b300614001019c84809470383c403020e50458c1100000185536809470383c403020e50458c110000000000000fc0041525a4f50410a202020202020000000fd0030901faa24000a202020202020011502032cf3420400230907078301000068030c001000884800681a000001013090e6e305c000e60605016262004037809470383c403020e50458c110000018816e809470383c403020e50458c11000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002f";
      miniMonBack = "00ffffffffffff001c525601010000002b1e0103802313782a6435a5544f9e27125054a1cf0071408180814081c09500d1c0a9c0b300023a801871382d40582c450059c21000001e000000fd003a901faa24000a202020202020000000fc0041525a4f50410a202020202020000000ff003030303030303030303030310a0181020338f1479001020304454523091f078301000067030c001000384867d85dc40148c000681a000001013a90e6e305c000e606050169694ffd8180a070381f403020350059c21000001e786e80a0703835403020360059c21000001a0f5c80a0703835403020360059c21000001a00000000000000000000000000000000005f";
      touchMon = "00ffffffffffff000469f116949a00001c1a010380221378ea82059256539529245054bfee0081c00101010101010101010101010101662156aa51001e30468f330058c21000001e000000fd00324c1e500f000a202020202020000000fc00415355532056543136380a2020000000ff0047374c4d54463033393537320a00b8";
      monConfig = {
        enable = true;
        position = "0x0";
      };
      miniMonConfig = monConfig // {
        mode = "1920x1080";
        rate = lib.mkDefault "144.0";
        gamma = "1.08:1.08:1.08";
      };
      touchMonConfig = monConfig // {
        mode = "1366x768";
        rate = "59.79";
      };
      disabled = {
        enable = false;
      };

      # intel hd 4600's max pixel rate caps out at 120hz
      hz120 = {
        rate = "120.0";
      };

      tanukiOutputs = {
        VGA-1 = disabled;
        HDMI-1 = disabled;
        DP-1 = disabled;
        HDMI-2 = disabled;
      };

      intel11400fOutputs = {
        DVI-D-0 = disabled;
        HDMI-0 = disabled;
        DP-0 = disabled;
        DP-1 = disabled;
      };

    in
    {
      "tanuki-left" = {
        fingerprint = { HDMI-2 = miniMonLeft; };
        config.HDMI-2 = miniMonConfig // hz120;
      };
      "tanuki-mid" = {
        fingerprint = { HDMI-2 = miniMonMid; };
        config.HDMI-2 = miniMonConfig // hz120;
      };
      "11400f-workstation" = {
        fingerprint = {
          DP-1 = miniMonMid;
          DVI-D-0 = touchMon;
          HDMI-0 = miniMonBack;
        };
        config = intel11400fOutputs // {
          DP-1 = miniMonConfig;
          DVI-D-0 = touchMonConfig // {
            position = "1920x0";
          };
        };
      };
      "11400f-stream" = {
        fingerprint = {
          DP-1 = miniMonMid;
          DVI-D-0 = touchMon;
          HDMI-0 = miniMonBack;
        };
        config.DP-1 = disabled;
        config.DVI-D-0 = touchMonConfig;
        config.HDMI-0 = miniMonConfig // {
          position = "1366x0";
        };
      };
    };

}
