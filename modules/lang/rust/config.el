;;; lang/rust/config.el -*- lexical-binding: t; -*-

(def-package! rust-mode
  :defer t
  :config
  (setq rust-indent-method-chain t)

  ;; This is necessary because both plugins are fighting for supremacy in
  ;; `auto-mode-alist', so rustic-mode *must* load second. It only needs to
  ;; happen once.
  ;;
  ;; rust-mode is still required for `racer'.
  (defun +rust|init ()
    "Switch to `rustic-mode', if it's available."
    (when (require 'rustic nil t)
      (rustic-mode)))
  (add-hook 'rust-mode-hook #'+rust|init)

  (set-docsets! '(rust-mode rustic-mode) "Rust")
  (when (featurep! +lsp)
    (add-hook 'rust-mode-local-vars-hook #'lsp!))

  ;; TODO PR these upstream
  (after! dtrt-indent
    (pushnew! dtrt-indent-hook-mapping-list
              '(rust-mode default rust-indent-offset)
              '(rustic-mode default rustic-indent-offset)))
  (when (featurep! :tools editorconfig)
    (after! editorconfig
      (pushnew! editorconfig-indentation-alist
                '(rust-mode rust-indent-offset)
                '(rustic-mode rustic-indent-offset)))))


(def-package! racer
  :unless (featurep! +lsp)
  :hook ((rust-mode rustic-mode) . racer-mode)
  :config
  (set-lookup-handlers! 'rust-mode
    :definition '(racer-find-definition :async t)
    :documentation '+rust-racer-lookup-documentation))


(def-package! rustic
  :when EMACS26+
  :after rust-mode
  :preface
  (setq rustic-rls-pkg (if (featurep! +lsp) 'lsp-mode))
  :config
  (setq rustic-indent-method-chain t
        rustic-flycheck-setup-mode-line-p nil
        ;; use :editor format instead
        rustic-format-on-save nil)

  ;; `rustic-setup-rls' uses `package-installed-p' unnecessarily, which breaks
  ;; because Doom lazy loads package.el.
  (defun +rust*disable-package-installed-p-call (orig-fn &rest args)
    (cl-letf (((symbol-function 'package-installed-p)
               (symbol-function 'ignore)))
      (apply orig-fn args)))
  (advice-add #'rustic-setup-rls :around #'+rust*disable-package-installed-p-call))


;;
;;; Tools

(def-package! cargo
  :after rust-mode
  :config
  (defvar +rust-keymap
    (if (boundp 'rustic-mode-map)
        rustic-mode-map
      rust-mode-map))
  (map! :map +rust-keymap
        :localleader
        (:prefix "b"
          :desc "cargo add"    "a" #'cargo-process-add
          :desc "cargo build"  "b" #'cargo-process-build
          :desc "cargo bench"  "B" #'cargo-process-bench
          :desc "cargo check"  "c" #'cargo-process-check
          :desc "cargo clippy" "C" #'cargo-process-clippy
          :desc "cargo doc"    "d" #'cargo-process-doc
          :desc "cargo run"    "r" #'cargo-process-run
          :desc "cargo search" "s" #'cargo-process-search
          :desc "cargo update" "u" #'cargo-process-update)
        (:prefix ("t" . "cargo test")
          :desc "all"          "a" #'cargo-process-test
          :desc "current file" "f" #'cargo-process-current-file-tests
          :desc "current test" "t" #'cargo-process-current-test)))
