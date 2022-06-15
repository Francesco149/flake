{ config, pkgs, user, configName, ... }:

let
  pythonPackages = pkgs.python39Packages; # adjust python version here as needed

  emacs-custom = (
    let
      emacsBuild = (pkgs.emacs.override {
        withGTK3 = true;
        withGTK2 = false;
      });
      emacsCustom = (pkgs.emacsPackagesFor emacsBuild).emacsWithPackages;
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
  );

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
        "https://addons.mozilla.org/firefox/downloads/file/3948477/i_dont_care_about_cookies-3.4.0.xpi"
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
      lockPref("browser.link.open_newwindow", 2); // open links in new windows (for exwm)
    '';
  };

  menuProg = "dmenu";

in with config; {
  home.username = "${user}";
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "22.05";
  home.packages = (with pkgs; [
    curl
    wget
    htop
    bpytop
    tokei
    pass
    xclip # required for pass show -c, also useful in general
    clipit # clipboard manager, to hold onto copied stuff when programs terminate
    git
    fusee-launcher
    mpv
    dmenu
    v4l-utils
    gh2md
    gist
    autorandr # save and detect xrandr configurations automatically

    pxplus-ibm-vga8-bin
    unifont
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    noto-fonts-extra
    font-awesome
    fira-mono
    emacs-all-the-icons-fonts

    pinentry-gnome
    gcr # required for pinentry-gnome?
    polkit_gnome
    gnome3.nautilus

    alacritty
    tdesktop
    chatterino7
    emacs-custom
    obs-studio
    simplescreenrecorder
    screenkey
    pavucontrol

    # TODO: would be nice to find a way to have these isolated in the custom
    # emacs instead of home-wide
    gopls
    ccls
    rnix-lsp
  ]) ++ (with pythonPackages; [
    jedi-language-server
  ]);

  home.sessionVariables = {
    EDITOR="vim";
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      xb="pushd ~/flake && nixos-rebuild switch --use-remote-sudo --flake .#${configName}; popd";
      xu="pushd ~/flake && nix flake update; popd";
      xub="xu && xb";
      xq="nix search nixpkgs";
      cam="mpv --profile=low-latency --untimed $(ls /dev/video* | ${menuProg})";
      eq="nix-env -f '<nixpkgs>' -qaP -A pkgs.emacsPackages | grep";
    };
    bashrcExtra = ''
      set -o vi
    '';
  };

  xdg.dataFile = {
    "vim/swap/.keep".text = "";
    "vim/backup/.keep".text = "";
    "vim/undo/.keep".text = "";
    "emacs/backup/.keep".text = "";
    "emacs/undo/.keep".text = "";
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

      (setq loli/polkit-agent-command "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1")
      (setq loli/browser-command "${firefox-custom}/bin/firefox")
    '';

    "git/config".source = ./git/gitconfig;
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
      polybar top --reload &
    '';
    config = {
      colors = {
        underline-1 = "#c792ea";
        foreground-alt = "#555";
        secondary = "#e60053";
      };

      "bar/top" = {
        #monitor = "HDMI-A-0";
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
  };

  services.parcellite = {
    enable = true;
    package = pkgs.clipit;
  };

  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [ vim-nix ];
    settings = {
      directory = [ "${xdg.dataHome}/vim/swap//" ];
      backupdir = [ "${xdg.dataHome}/vim/backup//" ];
      undofile = true;
      undodir = [ "${xdg.dataHome}/vim/undo//" ];
      shiftwidth = 2;
      tabstop = 2;
      relativenumber = true;
    };
    extraConfig = builtins.readFile ./vim/init.vim;
  };

  xsession = {
    enable = true;
    windowManager.command = ''
      exec ${emacs-custom}/bin/emacs --debug-init -mm
    '';
  };
  xsession.scriptPath = ".hm-xsession";

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

  gtk.enable = true;
  gtk.theme.name = "Adwaita-dark";
  gtk.theme.package = pkgs.gnome.gnome-themes-extra;

  # NOTE: private config files. comment out or provide your own
  xdg.configFile."gh2md/token".source = ./secrets/gh2md/token;
  home.file.".gist".source = ./secrets/gist/token;
}
