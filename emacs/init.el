;; this is generated by nix code, couldn't figure out a better way to do this
(load (expand-file-name "generated" (file-name-directory load-file-name)))

;; basic font settings
(custom-theme-set-faces
  'user
  '(default ((t (:family "PxPlus IBM VGA8" :height 120))))
  '(fixed-pitch ((t (:family "PxPlus IBM VGA8" :height 120))))
  '(variable-pitch ((t (:family "Noto Sans" :height 120 :weight medium))))
  '(italic ((t (:slant italic :underline nil))))

  '(org-document-title ((t (:inherit (shadow variable-pitch) :height 2.5))))
  '(org-level-1 ((t (:inherit (shadow variable-pitch) :weight bold :height 2.0))))
  '(org-level-2 ((t (:inherit (shadow variable-pitch) :weight bold :height 1.8))))
  '(org-level-3 ((t (:inherit (shadow variable-pitch) :weight bold :height 1.6))))
  '(org-level-4 ((t (:inherit (shadow variable-pitch) :weight bold :height 1.4))))
  '(org-level-5 ((t (:inherit (shadow variable-pitch) :weight bold :height 1.2))))
  '(org-level-6 ((t (:inherit (shadow variable-pitch) :weight bold :height 1.0))))
  '(org-level-7 ((t (:inherit (shadow variable-pitch) :weight bold :height 1.0))))
  '(org-level-8 ((t (:inherit (shadow variable-pitch) :weight bold :height 1.0))))

  ;; the fixed-pitch font is my pixel coding font. enforce it where needed, otherwise use the
  ;; serif antialiased font
  '(org-block ((t (:inherit fixed-pitch))))
  '(org-code ((t (:inherit (shadow fixed-pitch)))))
  '(org-document-info-keyword ((t (:inherit (shadow fixed-pitch)))))
  '(org-indent ((t (:inherit (org-hide fixed-pitch)))))
  '(org-meta-line ((t (:inherit (font-lock-comment-face fixed-pitch)))))
  '(org-property-value ((t (:inherit fixed-pitch))) t)
  '(org-special-keyword ((t (:inherit (font-lock-comment-face fixed-pitch)))))
  '(org-table ((t (:inherit fixed-pitch))))
  '(org-tag ((t (:inherit (shadow fixed-pitch) :weight bold :height 0.8))))
  '(org-verbatim ((t (:inherit (shadow fixed-pitch))))))

(set-variable 'frame-background-mode 'dark)

(defun loli/font-setup ()
  "font settings that need fonts to be loaded"

  ;; disable all bold fonts for my coding font
  (mapc (lambda (face)
          (when (string-match ".*PxPlus.*" (face-font face)) (set-face-attribute face nil :weight 'normal)))
   (face-list))

  ;; TODO: somehow the above also affects org mode variable pitch font for some reason. WHY?
  (custom-theme-set-faces 'user '(bold ((t (:weight bold)))))

  (set-fontset-font "fontset-default" 'adlam "Noto Sans Adlam")
  (set-fontset-font "fontset-default" 'anatolian "Noto Sans Anatolian Hieroglyphs")
  (set-fontset-font "fontset-default" 'arabic "Noto Sans Arabic")
  (set-fontset-font "fontset-default" 'aramaic "Noto Sans Imperial Aramaic Medium")
  (set-fontset-font "fontset-default" 'armenian "Noto Sans Armenian")
  (set-fontset-font "fontset-default" 'avestan "Noto Sans Avestan")
  (set-fontset-font "fontset-default" 'balinese "Noto Sans Balinese")
  (set-fontset-font "fontset-default" 'bamum "Noto Sans Bamum")
  (set-fontset-font "fontset-default" 'batak "Noto Sans Batak")
  (set-fontset-font "fontset-default" 'bengali "Noto Sans Bengali")
  (set-fontset-font "fontset-default" 'brahmi "Noto Sans Brahmi")
  (set-fontset-font "fontset-default" 'buginese "Noto Sans Buginese")
  (set-fontset-font "fontset-default" 'buhid "Noto Sans Buhid")
  (set-fontset-font "fontset-default" 'burmese "Noto Sans Myanmar")
  (set-fontset-font "fontset-default" 'canadian-aboriginal "Noto Sans Canadian Aboriginal")
  (set-fontset-font "fontset-default" 'carian "Noto Sans Carian")
  (set-fontset-font "fontset-default" 'chakma "Noto Sans Chakma")
  (set-fontset-font "fontset-default" 'cham "Noto Sans Cham")
  (set-fontset-font "fontset-default" 'cherokee "Noto Sans Cherokee")
  (set-fontset-font "fontset-default" 'cjk-misc "Noto Sans CJK SC Medium")
  (set-fontset-font "fontset-default" 'coptic "Noto Sans Coptic Medium")
  (set-fontset-font "fontset-default" 'cuneiform "Noto Sans Cuneiform")
  (set-fontset-font "fontset-default" 'cypriot-syllabary "Noto Sans Cypriot")
  (set-fontset-font "fontset-default" 'deseret "Noto Sans Deseret")
  (set-fontset-font "fontset-default" 'devanagari "Noto Sans Devanagari")
  (set-fontset-font "fontset-default" 'egyptian "Noto Sans Egyptian Hieroglyphs Medium")
  (set-fontset-font "fontset-default" 'ethiopic "Noto Sans Ethiopic")
  (set-fontset-font "fontset-default" 'georgian "Noto Sans Georgian")
  (set-fontset-font "fontset-default" 'glagolitic "Noto Sans Glagolitic")
  (set-fontset-font "fontset-default" 'gothic "Noto Sans Gothic")
  (set-fontset-font "fontset-default" 'gujarati "Noto Sans Gujarati")
  (set-fontset-font "fontset-default" 'gurmukhi "Noto Sans Gurmukhi")
  (set-fontset-font "fontset-default" 'han "Noto Sans CJK SC Medium")
  (set-fontset-font "fontset-default" 'han "Noto Sans CJK TC Medium" nil 'append)
  (set-fontset-font "fontset-default" 'hangul "Noto Sans CJK KR Medium")
  (set-fontset-font "fontset-default" 'hanunoo "Noto Sans Hanunoo")
  (set-fontset-font "fontset-default" 'hebrew "Noto Sans Hebrew")
  (set-fontset-font "fontset-default" 'inscriptional-pahlavi "Noto Sans Inscriptional Pahlavi")
  (set-fontset-font "fontset-default" 'inscriptional-parthian "Noto Sans Inscriptional Parthian")
  (set-fontset-font "fontset-default" 'javanese "Noto Sans Javanese")
  (set-fontset-font "fontset-default" 'kaithi "Noto Sans Kaithi")
  (set-fontset-font "fontset-default" 'kana "Noto Sans CJK JP Medium")
  (set-fontset-font "fontset-default" 'kannada "Noto Sans Kannada")
  (set-fontset-font "fontset-default" 'kayah-li "Noto Sans Kayah Li")
  (set-fontset-font "fontset-default" 'kharoshthi "Noto Sans Kharoshthi")
  (set-fontset-font "fontset-default" 'khmer "Noto Sans Khmer")
  (set-fontset-font "fontset-default" 'lao "Noto Sans Lao")
  (set-fontset-font "fontset-default" 'lepcha "Noto Sans Lepcha")
  (set-fontset-font "fontset-default" 'limbu "Noto Sans Limbu")
  (set-fontset-font "fontset-default" 'linear-b "Noto Sans Linear B")
  (set-fontset-font "fontset-default" 'lisu "Noto Sans Lisu")
  (set-fontset-font "fontset-default" 'lycian "Noto Sans Lycian")
  (set-fontset-font "fontset-default" 'lydian "Noto Sans Lydian")
  (set-fontset-font "fontset-default" 'malayalam "Noto Sans Malayalam")
  (set-fontset-font "fontset-default" 'mandaic "Noto Sans Mandaic")
  (set-fontset-font "fontset-default" 'meetei-mayek "Noto Sans Meetei Mayek")
  (set-fontset-font "fontset-default" 'mongolian "Noto Sans Mongolian")
  (set-fontset-font "fontset-default" 'tai-lue "Noto Sans New Tai Lue Medium")
  (set-fontset-font "fontset-default" 'nko "Noto Sans NKo Medium")
  (set-fontset-font "fontset-default" 'ogham "Noto Sans Ogham")
  (set-fontset-font "fontset-default" 'ol-chiki "Noto Sans Ol Chiki")
  (set-fontset-font "fontset-default" 'old-italic "Noto Sans Old Italic Medium")
  (set-fontset-font "fontset-default" 'old-persian "Noto Sans Old Persian Medium")
  (set-fontset-font "fontset-default" 'old-south-arabian "Noto Sans Old South Arabian Medium")
  (set-fontset-font "fontset-default" 'old-turkic "Noto Sans Old Turkic")
  (set-fontset-font "fontset-default" 'oriya "Noto Sans Oriya")
  (set-fontset-font "fontset-default" 'osage "Noto Sans Osage")
  (set-fontset-font "fontset-default" 'osmanya "Noto Sans Osmanya")
  (set-fontset-font "fontset-default" 'phags-pa "Noto Sans Phags Pa")
  (set-fontset-font "fontset-default" 'phoenician "Noto Sans Phoenician")
  (set-fontset-font "fontset-default" 'rejang "Noto Sans Rejang")
  (set-fontset-font "fontset-default" 'runic "Noto Sans Runic")
  (set-fontset-font "fontset-default" 'samaritan "Noto Sans Samaritan")
  (set-fontset-font "fontset-default" 'saurashtra "Noto Sans Saurashtra")
  (set-fontset-font "fontset-default" 'shavian "Noto Sans Shavian")
  (set-fontset-font "fontset-default" 'sinhala "Noto Sans Sinhala")
  (set-fontset-font "fontset-default" 'sinhala-archaic-number "Noto Sans Sinhala")
  (set-fontset-font "fontset-default" 'sundanese "Noto Sans Sundanese")
  (set-fontset-font "fontset-default" 'syloti-nagri "Noto Sans Syloti Nagri")
  ;;(set-fontset-font "fontset-default" 'syriac "Noto Sans Syriac Eastern")
  (set-fontset-font "fontset-default" 'syriac "Noto Sans Syriac Estrangela")
  ;;(set-fontset-font "fontset-default" 'syriac "Noto Sans Syriac Western")
  (set-fontset-font "fontset-default" 'tagalog "Noto Sans Tagalog")
  (set-fontset-font "fontset-default" 'tagbanwa "Noto Sans Tagbanwa")
  (set-fontset-font "fontset-default" 'tai-le "Noto Sans Tai Le")
  (set-fontset-font "fontset-default" 'tai-tham "Noto Sans Tai Tham")
  (set-fontset-font "fontset-default" 'tai-viet "Noto Sans Tai Viet")
  (set-fontset-font "fontset-default" 'tamil "Noto Sans Tamil")
  (set-fontset-font "fontset-default" 'telugu "Noto Sans Telugu")
  (set-fontset-font "fontset-default" 'thaana "Noto Sans Thaana")
  (set-fontset-font "fontset-default" 'thai "Noto Sans Thai")
  (set-fontset-font "fontset-default" 'tibetan "Noto Sans Tibetan")
  (set-fontset-font "fontset-default" 'tifinagh "Noto Sans Tifinagh")
  (set-fontset-font "fontset-default" 'ugaritic "Noto Sans Ugaritic")
  (set-fontset-font "fontset-default" 'vai "Noto Sans Vai")
  (set-fontset-font "fontset-default" 'yi "Noto Sans Yi")
  (set-fontset-font "fontset-default" 'symbol "Noto Color Emoji")

  (remove-hook 'focus-in-hook #'loli/font-setup)) ; only run hook once

;; there's some weird initialization order issues with daemon emacs
;; if we want fonts to be fully loaded when we run this code, we need to hook the first focus
(add-hook 'focus-in-hook #'loli/font-setup)

(load-theme 'xterm t)

;; undo-tree: remember multiple undo/redo paths and navigate them as a tree
(require 'undo-tree)
(global-undo-tree-mode)
(setq undo-tree-auto-save-history t)
(setq undo-tree-enable-undo-in-region nil)

;; dired settings (file browser)
(setq dired-listing-switches "-agho --group-directories-first")
(require 'dired-single) ; single buffer for dired
(require 'all-the-icons-dired)
(add-hook 'dired-mode-hook #'all-the-icons-dired-mode)

(require 'dired-hide-dotfiles)
(add-hook 'dired-mode-hook #'dired-hide-dotfiles-mode)

;; disable annoying elements
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-message t)
(setq ring-bell-function 'ignore)

;; this is a more important yes/no prompt, just overriding it with the basic one
(defalias 'yes-or-no-p 'y-or-n-p)

;; show line and column
(line-number-mode t)
(column-number-mode t)

;; emacs linum-mode is super slow, so I use this
(require 'nlinum-relative)
(add-hook 'prog-mode-hook #'nlinum-relative-mode)
(setq nlinum-relative-redisplay-delay 0)
(setq nlinum-relative-current-symbol "->")
(setq nlinum-relative-offset 0)

;; since I need to dynamically set common style settings, here are some reusable functions
(defun loli/style-tabs ()
  "Allow tabs for indentation"
  (interactive)
  (setq indent-tabs-mode t)
  (setq whitespace-style (delete 'tabs whitespace-style)))

(defun loli/style-spaces ()
  "Use only spaces for indentation and alignment"
  (interactive)
  (setq indent-tabs-mode nil)
  (add-to-list 'whitespace-style 'tabs))

;; default coding style
(defun loli/style-default ()
  "Default coding style settings"
  (setq whitespace-style '(face empty trailing))
  (loli/style-spaces)
  (set-default 'truncate-lines t)
  (whitespace-mode t))

;; tabs display as 2 spaces
(setq tab-width 2)

(add-hook 'prog-mode-hook #'loli/style-default)

;; C coding style
(setq c-default-style "linux")
(setq c-basic-offset 2)

;; go coding style
(add-hook 'go-mode-hook #'loli/style-tabs)
(add-hook 'before-save-hook #'gofmt-before-save)

;; electric-pairs: automatically close delimiter pairs
(setq electric-pair-pairs
      '((?\( . ?\))
        (?\[ . ?\])
        (?{ . })))

(electric-pair-mode t)

;; vertico: fancy fuzzy search everywhere
(require 'vertico)

(defun loli/minibuffer-backward-kill (arg)
  "when minibuffer is completing a file name delete up to parent folder, otherwise delete a word"
  (interactive "p")
  (if minibuffer-completing-file-name
      ;; borrowed from https://github.com/raxod502/selectrum/issues/498#issuecomment-803283608
      (if (string-match-p "/." (minibuffer-contents))
          (zap-up-to-char (- arg) ?/)
        (delete-minibuffer-contents))
    (delete-word (- arg))))

(define-key vertico-map (kbd "C-j") #'vertico-next)
(define-key vertico-map (kbd "C-k") #'vertico-previous)
(define-key vertico-map (kbd "M-h") #'loli/minibuffer-backward-kill)
(setq vertico-cycle t)

(setq completion-styles '(basic substring partial-completion flex)
      read-file-name-completion-ignore-case t
      read-buffer-completion-ignore-case t
      completion-ignore-case t)

(vertico-mode)

;; savehist: save minibuffer history and optionally other things
(require 'savehist)
(savehist-mode)

;; marginalia: provides extra info in vertico
(require 'marginalia)
(setq marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
(marginalia-mode)

;; embark: provides a hotkey to perform actions everywhere
(require 'embark)
(global-set-key (kbd "C->") #'embark-act)
(global-set-key (kbd "C-;") #'embark-dwim)
(global-set-key (kbd "C-h B") #'embark-bindings)

;; ace window: window manage utilities, also provides actions to create windows with embark
(require 'ace-window)
(setq aw-dispatch-always t)
(setq aw-scope 'frame) ; only choose windows within this frame
(setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
(global-set-key (kbd "M-o") #'ace-window)

(eval-when-compile
  (defmacro loli/embark-ace-action (fn)
    "ace-window prompt for embark"
    `(defun ,(intern (concat "loli/embark-ace-" (symbol-name fn))) ()
       (interactive)
       (with-demoted-errors "%s"
         (require 'ace-window)
         (let ((aw-dispatch-always t))
           (aw-switch-to-window (aw-select nil))
           (call-interactively (symbol-function ',fn)))))))

(define-key embark-file-map (kbd "o") (loli/embark-ace-action find-file))
(define-key embark-buffer-map (kbd "o") (loli/embark-ace-action switch-to-buffer))
(define-key embark-bookmark-map (kbd "o") (loli/embark-ace-action bookmark-jump))

;; avy: qutebrowser-like movement hints
(require 'avy)
(global-set-key (kbd "C-,") #'avy-goto-char)
(global-set-key (kbd "C-/") #'avy-goto-char-2)

;; which-key: display command completions
(require 'which-key)
(which-key-mode)

;; consult
;; fancier buffer switching with preview
(require 'consult)
(global-set-key (kbd "C-x b") #'consult-buffer)

;; tree-sitter
;; emacs' built-in font-lock is ridiculously slow and choppy when scrolling through lines quickly.
;; if syntax highlighting is not available with tree-sitter, we just don't use it because that
;; choppyness is just unacceptable

(global-font-lock-mode nil)
(require 'tree-sitter)
(require 'tree-sitter-langs)

;; global-tree-sitter-mode causes errors with exwm buffers. let's just do prog-mode
(add-hook 'prog-mode-hook #'turn-on-tree-sitter-mode)
(add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode)

;; lsp: language server
(require 'lsp-mode)
(lsp-enable-which-key-integration t)
(add-hook 'c-mode-hook #'lsp-deferred)
(add-hook 'c++-mode-hook #'lsp-deferred)
(add-hook 'python-mode-hook #'lsp-deferred)
(add-hook 'go-mode-hook #'lsp-deferred)
(add-hook 'nix-mode-hook #'lsp-deferred)

;; go
(require 'go-mode)
(add-hook 'before-save-hook #'gofmt-before-save)

;; nix
(require 'nix-mode)
(add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-mode))
(add-to-list 'lsp-language-id-configuration '(nix-mode . "nix"))

(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection '("rnix-lsp"))
                  :activation-fn (lsp-activate-on "nix")
                  :server-id 'nix))
(add-to-list 'lsp-enabled-clients 'nix)

;; python
(require 'lsp-jedi)
(add-to-list 'lsp-disabled-clients 'pyls)
(add-to-list 'lsp-enabled-clients 'jedi)

;; nix-direnv integration
(require 'direnv)
(direnv-mode)
(setq direnv-always-show-summary nil)
(setq direnv-use-faces-in-summary nil)

;; company: fancy auto complete
(require 'company)
(setq company-idle-delay 0)
(setq company-minimum-prefix-length 1)
(global-company-mode)

;; ccls: c/c++ auto complete
(require 'ccls)
(delete 'company-clang company-backends)

;; eldoc: display parameters in the echo area as function calls are typed
(add-hook 'emacs-lisp-mode-hook #'eldoc-mode)

;; org mode
(require 'org)

(defun loli/org-config ()
  "my org mode configuration"
  (org-indent-mode)
  (auto-fill-mode 0)
  (visual-line-mode)
  (setq evil-auto-indent 0)
  (variable-pitch-mode 1))

(add-hook 'org-mode-hook #'loli/org-config)
(setq org-ellipsis " ▾")

;; exwm: emacs as window manager
(require 'exwm-randr) ; multi-monitor support

;; assign workspaces to monitors
(setq exwm-randr-workspace-output-plist
      (append
        (apply #'append (mapcar (lambda (x) `(,x "DVI-D-0")) (number-sequence 0 4)))
        (apply #'append (mapcar (lambda (x) `(,x "HDMI-A-0")) (number-sequence 5 9)))))

;; use xrandr to set up my specific monitor config
;; TODO: pull this out into a machine specific config

(defun loli/shell (command)
  "run shell command asynchronously, sets buffer name to the command itself"
  (start-process-shell-command command nil command))

(defun loli/exwm-randr-screen-change ()
  "runs when the exwm screen changes. for example, when you plug/unplug a monitor"
  (loli/shell "autorandr --change --force")
  (message "autorandr config: %s"
           (string-trim (shell-command-to-string "autorandr --current"))))

;; NOTE: set up autorandr before using this
(add-hook 'exwm-randr-screen-change-hook #'loli/exwm-randr-screen-change)

(exwm-randr-enable)

;; NOTE: order of initialization is very important here.
;; randr must be initialized before exwm
;; exwm-enable should be called after everything is set up
(require 'exwm)

;; ctrl+q will enable the next key to be sent directly
;; I use this for ctrl-c when I want to copy in a X11 app for example
(define-key exwm-mode-map [?\C-q] 'exwm-input-send-next-key)

(defun loli/shell-launcher (command)
  "interactively ask for a shell command and run it asynchronously"
  (interactive (list (read-shell-command "$ ")))
  (loli/shell command))

(defun loli/passmenu ()
  "run password manager menu"
  (interactive)
  (loli/shell "passmenu"))

(defun loli/browser-command (profile)
  "shell command to start a browser with window class name browser-profile> and given profile"
  (format "librewolf --class browser-%s --no-remote -P %s" profile profile))

;; global exwm keybinds. they work regardless of input state.
;; you must restart emacs to apply changes to these
(setq exwm-input-global-keys
   `( ([?\s-w] . exwm-workspace-switch)
      ;; reset to line-mode (C-c C-k switches to char-mode via exwm-input-release-keyboard)
      ([?\C-c C-k] . exwm-input-release-keyboard)
      ([?\s-r] . exwm-reset)

      ([?\s-&] . loli/shell-launcher)
      ([?\s-d] . loli/shell-launcher) ;; TODO: application launcher
      ([?\s-U] . loli/passmenu)

      ;; this maps s-0 -> workspace 0, ..., s->9 -> workspace 9
      ;; and generates named, documented functions
      ,@(mapcar (lambda (i)
                  `(,(kbd (format "s-%d" i)) .
                    (lambda ()
                      (interactive)
                      (exwm-workspace-switch-create ,i))))
                (number-sequence 0 9))
     ))

;; initial number of workspaces
(setq exwm-workspace-number 10)

;; automatically move exwm buffer to current workspace when selected
(setq exwm-layout-show-all-buffers t)

;; display all exwm buffers in every workspace buffer list
(setq exwm-workspace-show-all-buffers t)

;; automatically send the mouse cursor to the selected workspace's display
;;(setq exwm-workspace-warp-cursor t)

;; window focus should follow the mouse pointer
(setq mouse-autoselect-window t
      focus-follows-mouse t)

;; these keys should always pass through to emacs
(setq exwm-input-prefix-keys
      '( ?\C-x
         ?\C-u
         ?\C-h
         ?\C-g
         ?\C-w
         ?\M-x
         ?\M-o
         ?\s-U
         ?\C-,
         ?\C-/
         ?\M-:
         ?\C-\ ))  ;; Ctrl+Space

(defun loli/exwm-update-class ()
  "rename buffers according to window title for exwm"
  (exwm-workspace-rename-buffer exwm-class-name))

(add-hook 'exwm-update-class-hook #'loli/exwm-update-class)

(defun loli/exwm-update-title ()
  "called when exwm buffers are renamed"
  (pcase exwm-class-name
    ("browser-default" (exwm-workspace-rename-buffer (format "(default): %s" exwm-title)))
    ("browser-side" (exwm-workspace-rename-buffer (format "(side): %s" exwm-title)))))

(add-hook 'exwm-update-title-hook #'loli/exwm-update-title)

(defun loli/symbol (pre suf)
  "returns symbol of loli/<pre>-<suf>"
  (intern (format "loli/%s-%s" pre suf)))

(defun loli/symbol-value (pre suf)
  "returns symbol value of loli/<pre>-<suf>"
  (symbol-value (loli/symbol pre suf)))

;; pin class names to specific windows and workspaces.
;; this doesn't seem to consistently work, probably because the window is not fully initialized.
;; TODO: find a better way.
;; for now, I'm gonna call it good enough as it at least picks up my chatterino correctly.

(defun loli/exwm--do-pin-to-window (workspace window)
  "pins the current exwm window to workspace, window.
requires (setq exwm-layout-show-all-buffers t exwm-workspace-show-all-buffers t)"
  (let ( (buf (current-buffer)) )
    (unless (window-dedicated-p window)
      (set-window-buffer window buf)
      (message "pinned %s to workspace %d %s" buf workspace window))))

;; NOTE: these are pcase macros, so they must return non-nil to signal the the expr matched.
;;       this is basically a hacky way to execute code when the expr matches within a pcase
;;       macro to clean up and shorten code

(pcase-defmacro loli/exwm-pin-to-window (workspace)
  "moves class-name to workspace and loli/<class-name>-window.
note that you are responsible for defining and setting loli/<class-name>-window.
requires (setq exwm-layout-show-all-buffers t exwm-workspace-show-all-buffers t)"
  `(pred (lambda (x)
           (loli/exwm--do-pin-to-window ,workspace (loli/symbol-value exwm-class-name "window"))
           t)))

(pcase-defmacro loli/exwm-pin-to-workspace (workspace)
  "moves the current exwm window to workspace."
  `(pred (lambda (x)
           (let ( (buf (current-buffer)) )
             (exwm-workspace-move-window ,workspace)
             (message "pinned %s to workspace %d" buf ,workspace))
           t)))

(rx-define loli/rx-exact (&rest r)
  (seq string-start r string-end))

(rx-define loli/rx-or-exact (&rest r)
  (loli/rx-exact (or r)))

(pcase-defmacro loli/one-of-strings (&rest r)
  `(rx (loli/rx-or-exact ,@r)))

(pcase-defmacro loli/exwm--apply-any-of (func workspace &rest r)
  `(and (loli/one-of-strings ,@r)
        (,func ,workspace)))

(pcase-defmacro loli/exwm-pin-to-window-any-of (workspace &rest r)
  `(loli/exwm--apply-any-of loli/exwm-pin-to-window ,workspace ,@r))

(pcase-defmacro loli/exwm-pin-to-workspace-any-of (workspace &rest r)
  `(loli/exwm--apply-any-of loli/exwm-pin-to-workspace ,workspace ,@r))

(defun loli/exwm-manage-finish ()
  "called when a new window is captured by exwm"
  (pcase exwm-class-name
    ((loli/exwm-pin-to-window-any-of 5 "browser-side" "chatterino"))
    ((loli/exwm-pin-to-workspace-any-of 1 "browser-default"))
    ((loli/exwm-pin-to-workspace-any-of 6 "TelegramDesktop"))
    ((loli/one-of-strings "mpv")
      (exwm-floating-toggle-floating)
      (exwm-layout-toggle-mode-line))))

(add-hook 'exwm-manage-finish-hook #'loli/exwm-manage-finish)

(defun loli/exwm-layout ()
  "set up personal exwm workspace layout. only run this once at startup"

  ;; set up 2nd screen layout
  (exwm-workspace-switch-create 5)
  (setq loli/browser-side-window (selected-window))
  (setq loli/chatterino-window (split-window-horizontally (- (window-width) 45)))

  ;; I map workspaces to the same number key as their index to make it less confusing
  ;; when I move windows with C-c RET.
  ;; we want to start at workspace 1, the first on the keyboard
  (exwm-workspace-switch-create 1)
  (setq loli/main-window (selected-window))

  ;; startup programs
  (mapc #'loli/shell
        `( ,loli/polkit-agent-command
           "chatterino"
           "telegram-desktop"
           ,(loli/browser-command "default")
           ,(loli/browser-command "side") ))

  ;; there's some update focus nil window errors on startup.
  ;; this might fix it
  (select-window loli/main-window))

(add-hook 'after-init-hook #'loli/exwm-layout)
(exwm-enable)

;; other keybinds
(global-set-key (kbd "C-c C-r") #'sudo-edit-find-file)
(global-set-key (kbd "C-c SPC") #'whitespace-cleanup)

;; general: easier way to set up prefixed keybinds
(require 'general)

(general-create-definer loli/leader-keys
  :keymaps '(normal insert visual emacs)
  :prefix "SPC"
  :global-prefix "C-SPC")

;; evil mode: vim keybinds because emacs keybinds are wack

(setq evil-want-integration t)
(setq evil-want-keybinding nil)

;; C-u scrolls like in vim instead of doing the emacs thing
(setq evil-want-C-u-scroll t)

;; C-i inserts a tab instead of doing vim-like jump
(setq evil-want-C-i-jump nil)

;; indent size
(setq evil-shift-width 2)

;; hook to disable evil mode in certain modes
(defun loli/evil-hook ()
  (dolist (mode '(git-rebase-mode))
    (add-to-list 'evil-emacs-state-modes mode)))

(add-hook 'evil-mode-hook #'loli/evil-hook)

(require 'evil)
(evil-mode t)
(define-key evil-insert-state-map (kbd "C-g") #'evil-normal-state)

(require 'evil-collection)
(evil-collection-init)

(general-evil-setup t)
(evil-set-undo-system 'undo-tree)

;; ctrl-h is backspace, saves some hand movement
(define-key evil-insert-state-map (kbd "C-h") #'evil-delete-backward-char-and-join)

(evil-collection-define-key 'normal 'dired-mode-map
  "h" 'dired-single-up-directory
  "l" 'dired-single-buffer
  "H" 'dired-hide-dotfiles-mode)

;; visual mode is when lines that are too long are wrapped and they appear as multiple lines.
;; a normal next line command would go to the next real line, but next-visual-line goes to the
;; next apparent line, so that you can move between lines of a huge wrapped line
(evil-global-set-key 'motion "j" #'evil-next-visual-line)
(evil-global-set-key 'motion "k" #'evil-previous-visual-line)

;; default to normal mode for these modes
(evil-set-initial-state 'messages-buffer-mode 'normal)
(evil-set-initial-state 'dashboard-mode 'normal)

;; I don't want :q to close emacs entirely, it should just kill the buffer
(evil-ex-define-cmd "q" 'kill-this-buffer)
(evil-ex-define-cmd "quit" 'evil-quit)

;; hydra lets you create custom prompts with their own keybinds and a timeout
(require 'hydra)
(defhydra loli/text-scale ()
  "scale text"
  ("j" text-scale-increase "in")
  ("k" text-scale-decrease "out"))

(loli/leader-keys
  "t" '(:ignore t :which-key "toggle prompts")
  "ts" '(loli/text-scale/body :which-key "scale text"))
