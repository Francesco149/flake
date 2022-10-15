{ config, pkgs, configName, ... }:
let

  firefox-custom = pkgs.wrapFirefox pkgs.firefox-unwrapped {
    extraPolicies = {
      CaptivePortal = false;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFirefoxAccounts = true;
      DisableProfileImport = true;
      DisableProfileRefresh = true;
      DisableSystemAddonUpdate = true;

      FirefoxHome = {
        Pocket = false;
        Snippets = false;
      };

      UserMessaging = {
        ExtensionRecommendations = false;
        SkipOnboarding = true;
      };

      Extensions.Install = [
        "https://addons.mozilla.org/firefox/downloads/file/3933192/ublock_origin-1.42.4.xpi"
        "https://addons.mozilla.org/firefox/downloads/file/3970126/consent_o_matic-1.0.8.xpi"
        "https://addons.mozilla.org/firefox/downloads/file/3941589/return_youtube_dislikes-3.0.0.1.xpi"
        "https://addons.mozilla.org/firefox/downloads/file/3958238/sponsorblock-4.5.1.xpi"
        "https://addons.mozilla.org/firefox/downloads/file/3059971/image_search_options-3.0.12.xpi"
        "https://cdn.frankerfacez.com/script/frankerfacez-4.0-an+fx.xpi"
        "https://addons.mozilla.org/firefox/downloads/file/3945159/7tv-2.2.2.xpi"
      ];
    };

    extraPrefs = ''
      // show more ssl cert infos
      lockPref("security.identityblock.show_extended_validation", true);

      // DDG is fucked so might as well use a better botnet
      lockPref("browser.policies.runOncePerModification.setDefaultSearchEngine", "Google");

      lockPref("privacy.sanitize.sanitizeOnShutdown", false); // don't clear cookies/history
      lockPref("browser.startup.page", 3); // restore tabs on startup

      //this seems to cause bugs when i click links on a fullscreened firefox
      //lockPref("browser.link.open_newwindow", 2); // open links in new windows (for exwm)

      // fuck off with this sponsored shit
      lockPref("services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsored", false);
      lockPref("services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsoredTopSites", false);
    '';
  };

  tdesktop-wrapped = pkgs.writeShellScriptBin "telegram-desktop" ''
    exec env XDG_CURRENT_DESKTOP=gnome ${pkgs.tdesktop}/bin/telegram-desktop "$@"
  '';

in with config; {

  imports = [../home.nix ];

  home.packages = with pkgs; [
    font-awesome
    fira-mono
    roboto

    v4l-utils
    gh2md
    gist
    autorandr # save and detect xrandr configurations automatically
    fusee-launcher
    pass

    pinentry-gnome
    gcr # required for pinentry-gnome?
    polkit_gnome
    gnome.nautilus
    transmission-gtk

    dmenu
    cwm
    maim
    firefox-custom
    tdesktop-wrapped
    chatterino7
    obs-studio
    simplescreenrecorder
    screenkey
    pavucontrol
    krita
    tor-browser-bundle-bin

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
  ];

  xsession = {
    enable = true;
    windowManager.command = ''
      ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
      chatterino &
      firefox &
      telegram-desktop &
      exec ${pkgs.cwm}/bin/cwm -c ${xdg.configHome}/cwm/cwmrc
    '';
  };

  xsession.scriptPath = ".hm-xsession";

  xdg.configFile = {
    "cwm/cwmrc".source = ../cwm/cwmrc;
  };

  programs.autorandr.enable = true;
  programs.autorandr.profiles = let
    main-fingerprints = {
      DVI-D-1 = "00ffffffffffff000469f827000000000f17010480355a78ea9de5a654549f260d505400000001010101010101010101010101010101087080a07038454030203500e00e1100001e775c80a070383a4030203500e00e1100001e000000fc0056473234380a202020202020200000001000000000000000000000000000000039";
      HDMI-A-0 = "00ffffffffffff004c2d38060000000027130103801009780aee91a3544c99260f5054bfef80714f8100814081809500950fa940b300023a801871382d40582c4500a05a0000001e011d00bc52d01e20b8285540a05a0000001e000000fd00184b1a5117000a202020202020000000fc0053796e634d61737465720a2020012e020323f14b930405140312101f2021222309070783010000e2000f67030c001000b82d011d80d0721c1620102c2580a05a0000009e011d8018711c1620582c2500a05a0000009e011d007251d01e206e285500a05a0000001e8c0ad090204031200c405500a05a000000188c0ad08a20e02d10103e9600a05a00000018000057";
    };
  in {
    "with-otherpc" = {
      fingerprint = main-fingerprints;
      config.DVI-D-1 = {
        enable = true;
        primary = true;
        mode = "1920x1080";
        rate = "120.0";
        position = "0x0";
      };
      config.HDMI-A-0 = {
        enable = true;
        mode = "1920x1080";
        rate = "60.0";
        position = "1920x0";
      };
    };
  };

  services.barrier.client = {
    enable = true;
    server = "192.168.1.202";
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
      monitor = "HDMI-A-0";
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
      click-left = ''
        emacsclient -e "(proced)"
      '';
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
      mount-0 = "/home";
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
    "*xterm*allowBoldFonts" =  false;
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
    pinentryFlavor = "gnome3";
  };

  services.gnome-keyring.enable = true;

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "text/html" = "firefox.desktop";
    "application/x-extension-htm" = "firefox.desktop";
    "application/x-extension-html" = "firefox.desktop";
    "application/x-extension-shtml" = "firefox.desktop";
    "application/xhtml+xml" = "firefox.desktop";
    "application/x-extension-xhtml" = "firefox.desktop";
    "application/x-extension-xht" = "firefox.desktop";
  };

  home.sessionVariables.DEFAULT_BROWSER = "${firefox-custom}/bin/firefox";

  programs.bash.shellAliases = {
    git-su = "sudo su -s '${pkgs.bash}/bin/bash' - git";
  };

  programs.bash.bashrcExtra = ''
    git-init() {
      sudo -u git sh -c "mkdir \$HOME/$1.git && git -C \$HOME/$1.git init --bare"
    }
  '';

}
