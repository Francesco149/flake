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

(defun loli/make-browser-command (class &optional extra-params)
  "shell command to start a new browser window with window class browser-<class>"
  (format "%s --class browser-%s %s" loli/browser-command class (or extra-params "")))

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
      ([?\C-$] . loli/screenshot-to-clipboard)

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
    ("browser-web" (exwm-workspace-rename-buffer (format "(web): %s" exwm-title)))))

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

(defun loli/exwm-toggle-floating ()
  "toggle floating and mode line on a window"
  (message "floating %s" exwm-title)
  (exwm-floating-toggle-floating)
  (exwm-layout-toggle-mode-line))

;; TODO: figure out how to do this with exwm-manage-configurations

(defun loli/exwm-manage-finish ()
  "called when a new window is captured by exwm"
  (if exwm--floating-frame
      ;; don't try to pin floating windows, just hide the modeline.
      ;; for example if chatterino opens its settings, it would remove the chatterino window from its emacs window
      ;;  if I didn't do this
      (exwm-layout-toggle-mode-line)

    ;; not a floating window, so we can apply these rules
    (pcase exwm-class-name
      ((loli/exwm-pin-to-window-any-of 5 "browser-web" "chatterino"))
      ((loli/exwm-pin-to-workspace-any-of 6 "TelegramDesktop"))
      ((loli/one-of-strings "mpv")
       (loli/exwm-toggle-floating)))))

(add-hook 'exwm-manage-finish-hook #'loli/exwm-manage-finish)

(defun loli/exwm-layout ()
  "set up personal exwm workspace layout. only run this once at startup"

  ;; set up 2nd screen layout
  (exwm-workspace-switch-create 5)
  (setq loli/browser-web-window (selected-window))
  (setq loli/chatterino-window (split-window-horizontally (- (window-width) 45)))

  ;; I map workspaces to the same number key as their index to make it less confusing
  ;; when I move windows with C-c RET.
  ;; we want to start at workspace 1, the first on the keyboard
  (exwm-workspace-switch-create 1)
  (setq loli/main-window (selected-window))

  ;; startup programs
  ;; the browser without --no-remote is the one that opens links I click in programs
  (mapc #'loli/shell
        `( ,loli/polkit-agent-command
           loli/chatterino-command
           loli/telegram-command
           ,(loli/make-browser-command "web") ))

  ;; there's some update focus nil window errors on startup.
  ;; this might fix it
  (select-window loli/main-window))

(add-hook 'after-init-hook #'loli/exwm-layout)
(exwm-enable)
