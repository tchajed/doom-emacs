;;; term/term/autoload.el -*- lexical-binding: t; -*-

(defun +term--kill-dedicated (window buffer)
  (when (window-live-p window)
    (delete-window window))
  (when (buffer-live-p buffer)
    (set-process-query-on-exit-flag (get-buffer-process buffer) nil)
    (kill-buffer buffer)))

;;;###autoload
(defun +term/toggle (arg)
  "Toggle a persistent terminal popup window.

If popup is visible but unselected, select it.
If prefix ARG, recreate the term buffer."
  (interactive "P")
  (require 'multi-term)
  (let ((multi-term-dedicated-select-after-open-p t)
        (multi-term-dedicated-buffer-name
         (format "doom:term-popup:%s"
                 (if (bound-and-true-p persp-mode)
                     (safe-persp-name (get-current-persp))
                   "main"))))
    (let* ((buffer (multi-term-get-buffer nil t))
           (window (get-buffer-window buffer)))
      (when arg
        (+term--kill-dedicated window buffer)
        (setq buffer (multi-term-get-buffer nil t))) ; recreates buffer
      (if (and (window-live-p window)
               (buffer-live-p buffer))
          (if (eq (selected-window) window)
              (delete-window window)
            (select-window window)
            (when (bound-and-true-p evil-local-mode)
              (evil-change-to-initial-state))
            (goto-char (point-max)))
        (setenv "PROOT" (or (doom-project-root) default-directory))
        (with-current-buffer buffer
          (doom|mark-buffer-as-real)
          (multi-term-internal))
        (unless (window-live-p window)
          (when-let (window
                     (display-buffer-in-side-window
                      buffer `((window-height . ,multi-term-dedicated-window-height))))
            (select-window window)))))))

;;;###autoload
(defun +term/here ()
  "Open a terminal buffer in the current window."
  (interactive)
  ;; Doom's switch-buffer hooks prevent themselves from triggering when
  ;; switching from buffer A back to A. Because `multi-term' uses `set-buffer'
  ;; before `switch-to-buffer', the hooks don't trigger, so we use this
  ;; roundabout way to trigger them properly.
  (switch-to-buffer (save-window-excursion (multi-term))))


;; TODO +term/frame -- dedicate current frame to term buffers
;; TODO +term/frame-quite -- revert frame to before +term/frame
