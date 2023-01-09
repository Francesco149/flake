{ config, pkgs, user, configName, lib, ... }:

let
  pythonPackages = pkgs.python39Packages; # adjust python version here as needed

  themeName = "Adwaita-dark";

  emacs-custom = (
    let
      emacsCustom = (pkgs.emacsPackagesFor pkgs.emacsPgtk).emacsWithPackages;
    in
      emacsCustom (epkgs: with epkgs; [
        org org-superstar
        undo-tree
        sudo-edit
        nix-mode
        go-mode
        magit
        dired-single # single buffer for dired
        all-the-icons-dired
        dired-hide-dotfiles
        vertico # fancy fuzzy completion everywhere
        embark # quick actions on current completion selection
        embark-consult
        ace-window # window management utils, also integrates with embark
        marginalia # extra info in vertico
        which-key # display all possible command completions
        nlinum-relative # relative line number
        company lsp-mode lsp-jedi ccls # auto complete
        evil # vim-like keybindings
        evil-collection # pre-configured evil keybinds for things not covered by core evil
        general # makes it easier to customize keybindings
        hydra # creates a prompt with timeout with its own keybinds
        tree-sitter tree-sitter-langs # way faster syntax gl than emacs' built in
        direnv # integrate nix-direnv into emacs
        exwm # emacs as a window manager
        consult # fancy buffer switching
        avy # fancy jump to char
      ])

      # TODO: remove a lot of these pkgs since I only use emacs for org mode now
      );

  firefox-custom = pkgs.wrapFirefox pkgs.firefox-esr-unwrapped {
    nixExtensions = let
      addon = pkgs.fetchFirefoxAddon;
    in [
      (addon {
        name = "ublock";
        url = "https://addons.mozilla.org/firefox/downloads/file/3933192/ublock_origin-1.42.4.xpi";
        sha256 = "1kirlfp5x10rdkgzpj6drbpllryqs241fm8ivm0cns8jjrf36g5w";
      })
      (addon {
        name = "consent-o-matic";
        url = "https://addons.mozilla.org/firefox/downloads/file/3970126/consent_o_matic-1.0.8.xpi";
        sha256 = "1gpd37w75wfn5rn4py3p7bpnz25iw7pp14gvjww2pcic3zscqx8a";
      })
      (addon {
        name = "return-youtube-dislike";
        url = "https://addons.mozilla.org/firefox/downloads/file/3941589/return_youtube_dislikes-3.0.0.1.xpi";
        sha256 = "00kx306pf8zxy8bpar03b226a5vmz298xaf98vzyffwfbnj89h0k";
      })
      (addon {
        name = "sponsorblock";
        url = "https://addons.mozilla.org/firefox/downloads/file/3958238/sponsorblock-4.5.1.xpi";
        sha256 = "017lqljl18i7qhpd1q1qix6cb9s2x9k4zzaighfdmr3d0rhwfqwc";
      })
      (addon {
        name = "image-search-options";
        url = "https://addons.mozilla.org/firefox/downloads/file/3059971/image_search_options-3.0.12.xpi";
        sha256 = "0s6hdy6cbcipjqljqhzbrzni1c527gm5ia822ghinay3gxcxig8z";
      })
      (addon {
        name = "frankerfacez";
        url = "https://cdn.frankerfacez.com/script/frankerfacez-4.0-an+fx.xpi";
        sha256 = "0kx0dax1cv4h7hkbisw96sh2qxpmfgq1sbd49531kycwmnnq1z2k";
      })
      (addon {
        name = "7tv";
        url = "https://addons.mozilla.org/firefox/downloads/file/3945159/7tv-2.2.2.xpi";
        sha256 = "01bl3mqd875647fcm1sbssf0p88yid4fw8ia0makq9qlcincdpjr";
      })
      (addon {
        name = "libredirect";
        url = "https://addons.mozilla.org/firefox/downloads/file/4016524/libredirect-2.3.1.xpi";
        sha256 = "1a9zq9ag0iqfzxkjbkl8dfpi1aa7sw32cylqrqiacgyf733dqfdk";
      })
      (addon {
        name = "purpleadblock";
        url = "https://github.com/arthurbolsoni/Purple-adblock/releases/download/2.5.0.10/purple-adblock-2.5.0.10-unsigned-firefox.xpi";
        sha256 = "10x64l3079wx70s5f5wn2cysdzagp1sgkx23yv7dnyy17b898i40";
      })
    ];

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

      lockPref("media.ffmpeg.vaapi.enabled", true);
    '';
  };

  # some programs don't use the gtk file picker by default.
  # tricking them into thinking I'm running gnome seems to work
  fix-file-picker = binary: pkgs.writeShellScriptBin (baseNameOf binary) ''
    exec env XDG_CURRENT_DESKTOP=gnome ${binary} "$@"
  '';

  # some gnome applications don't follow gtk theme by default
  fix-theme = binary: pkgs.writeShellScriptBin (baseNameOf binary) ''
    exec env GTK_THEME=${themeName} ${binary} "$@"
  '';

  fix-rdd-sandbox = binary: pkgs.writeShellScriptBin (baseNameOf binary) ''
    exec env MOZ_DISABLE_RDD_SANDBOX=1 ${binary} "$@"
  '';

in with config; {

  imports = [
    ../vim/home.nix
  ];

  caches.cachix = [
    # nix-prefetch-url 'https://cachix.org/api/v1/cache/${name}'
    { name = "nix-community"; sha256 = "1rgbl9hzmpi5x2xx9777sf6jamz5b9qg72hkdn1vnhyqcy008xwg"; }
    { name = "lolisamurai"; sha256 = "0manvwxjwvv3mk32jwfpbail5lc0h3v2q9c998r21z1vhcjdgb8i"; }
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
    bpytop
    tokei
    git
    ffmpeg
    yt-dlp
    youtube-dl
    aria
    nnn
    picotts

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

    #emacs-custom
    emacs-all-the-icons-fonts
    gopls
    ccls
    rnix-lsp

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

    nitrogen
    pinentry-gnome
    gcr # required for pinentry-gnome?
    polkit_gnome
    (fix-theme "${pkgs.gnome.nautilus}/bin/nautilus")
    transmission-gtk

    dmenu
    maim
    (fix-rdd-sandbox "${firefox-custom}/bin/firefox")
    (fix-file-picker "${pkgs.tdesktop}/bin/telegram-desktop")
    chatterino7
    obs-studio
    simplescreenrecorder
    screenkey
    pavucontrol
    krita
    tor-browser-bundle-bin
    quickemu
    qemu_kvm
    (fix-file-picker "${pkgs.shotcut}/bin/shotcut")
    libreoffice

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

  ]) ++ (with pythonPackages; [

    jedi-language-server

  ]);


  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      xb="pushd ~/flake && nixos-rebuild switch --use-remote-sudo --flake .#${configName}; popd";
      xt="pushd ~/flake && nixos-rebuild test --use-remote-sudo --flake .#${configName}; popd";
      xu="pushd ~/flake && nix flake update; popd";
      xub="xu && xb";
      xq="nix search nixpkgs";
      eq="nix-env -f '<nixpkgs>' -qaP -A pkgs.emacsPackages | grep";
      yt-date="yt-dlp --skip-download --get-filename --output '%(upload_date)s'";
    };
    bashrcExtra = ''
      set -o vi
    '';
  };

  xsession = {
    enable = true;
    windowManager.command = ''
      ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
      nitrogen --set-auto ${xdg.dataHome}/wallpaper.jpg
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
    "emacs/backup/.keep".text = "";
    "emacs/undo/.keep".text = "";
    "barrier/SSL/Fingerprints/TrustedServers.txt".source = ./barrier/TrustedServers.txt;
    "wallpaper.jpg".source = ./wallpaper.jpg;
    "chatterino/Settings/window-layout.json".source = ./chatterino/window-layout.json;
  };

  xdg.configFile = {
    "emacs/init.el".source = ./emacs/init.el;
    "emacs/xterm-theme.el".source = ./emacs/xterm-theme.el;

    # extra elisp that needs to include strings generated by nix
    "emacs/generated.el".text = ''
      ;; don't clutter my fs with backup/undo files
      (setq backup-directory-alist
        `((".*" . "${xdg.dataHome}/emacs/backup//")))
      (setq auto-save-file-name-transforms
        `((".*" "${xdg.dataHome}/emacs/backup//" t)))
      (setq undo-tree-history-directory-alist '(("." . "${xdg.dataHome}/emacs/undo")))
    '';

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

  programs.autorandr.enable = true;
  programs.autorandr.profiles = let
    main-fingerprints = {
      HDMI-A-0= "00ffffffffffff001ee456010000000009200103807341780bcf74a75546982410494b2108008180950090400101a940b300614001019c84809470383c403020e50458c1100000185536809470383c403020e50458c110000000000000fc0041525a4f50410a202020202020000000fd0030901faa24000a202020202020011502032cf3420400230907078301000068030c001000884800681a000001013090e6e305c000e60605016262004037809470383c403020e50458c110000018816e809470383c403020e50458c11000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002f";
    };
  in {
    "single-monitor" = {
      fingerprint = main-fingerprints;
      config.HDMI-A-0 = {
        enable = true;
        mode = "1920x1080";
        rate = lib.mkDefault "144.0";
        position = "0x0";
        gamma="1.08:1.08:1.08";
      };
    };
  };

}
