;;; ui/doom/config.el -*- lexical-binding: t; -*-

(defvar +doom-solaire-themes
  '((doom-city-lights . t)
    (doom-dracula . t)
    (doom-molokai)
    (doom-nord . t)
    (doom-nord-light . t)
    (doom-nova)
    (doom-one . t)
    (doom-one-light . t)
    (doom-opera . t)
    (doom-solarized-light)
    (doom-spacegrey)
    (doom-vibrant)
    (doom-tomorrow-night))
  "An alist of themes that support `solaire-mode'. If CDR is t, then use
`solaire-mode-swap-bg'.")


;;
;; Packages

;; <https://github.com/hlissner/emacs-doom-theme>
(def-package! doom-themes
  :defer t
  :init
  (unless doom-theme
    (setq doom-theme 'doom-one))
  :config
  ;; improve integration w/ org-mode
  (add-hook 'doom-load-theme-hook #'doom-themes-org-config)
  ;; more Atom-esque file icons for neotree/treemacs
  (when (featurep! :ui neotree)
    (add-hook 'doom-load-theme-hook #'doom-themes-neotree-config)
    (setq doom-neotree-enable-variable-pitch t
          doom-neotree-file-icons 'simple
          doom-neotree-line-spacing 2))
  (when (featurep! :ui treemacs)
    (add-hook 'doom-load-theme-hook #'doom-themes-treemacs-config)
    (setq doom-treemacs-enable-variable-pitch t)))


(def-package! solaire-mode
  :defer t
  :init
  (defun +doom|solaire-mode-swap-bg-maybe ()
    (when-let (rule (assq doom-theme +doom-solaire-themes))
      (require 'solaire-mode)
      (when (cdr rule)
        (solaire-mode-swap-bg)
        (with-eval-after-load 'ansi-color
          (when-let (color (face-background 'default))
            (setf (aref ansi-color-names-vector 0) color))))))
  (add-hook 'doom-load-theme-hook #'+doom|solaire-mode-swap-bg-maybe t)
  :config
  ;; fringe can become unstyled when deleting or focusing frames
  (add-hook 'focus-in-hook #'solaire-mode-reset)
  ;; Prevent color glitches when reloading either DOOM or loading a new theme
  (add-hook! :append '(doom-load-theme-hook doom-reload-hook)
    #'solaire-mode-reset)
  ;; org-capture takes an org buffer and narrows it. The result is erroneously
  ;; considered an unreal buffer, so solaire-mode must be restored.
  (add-hook 'org-capture-mode-hook #'turn-on-solaire-mode)

  ;; On Emacs 26+, when point is on the last line and solaire-mode is remapping
  ;; the hl-line face, hl-line's highlight bleeds into the rest of the window
  ;; after eob.
  (when EMACS26+
    (defun +doom--line-range ()
      (cons (line-beginning-position)
            (cond ((let ((eol (line-end-position)))
                     (and (=  eol (point-max))
                          (/= eol (line-beginning-position))))
                   (1- (line-end-position)))
                  ((or (eobp)
                       (= (line-end-position 2) (point-max)))
                   (line-end-position))
                  ((line-beginning-position 2)))))
    (setq hl-line-range-function #'+doom--line-range))

  ;; Because fringes can't be given a buffer-local face, they can look odd, so
  ;; we remove them in the minibuffer and which-key popups (they serve no
  ;; purpose there anyway).
  (defun +doom|disable-fringes-in-minibuffer (&rest _)
    (set-window-fringes (minibuffer-window) 0 0 nil))
  (add-hook 'solaire-mode-hook #'+doom|disable-fringes-in-minibuffer)

  (defun doom*no-fringes-in-which-key-buffer (&rest _)
    (+doom|disable-fringes-in-minibuffer)
    (set-window-fringes (get-buffer-window which-key--buffer) 0 0 nil))
  (advice-add 'which-key--show-buffer-side-window :after #'doom*no-fringes-in-which-key-buffer)

  (add-hook! '(minibuffer-setup-hook window-configuration-change-hook)
    #'+doom|disable-fringes-in-minibuffer)

  (solaire-global-mode +1))
