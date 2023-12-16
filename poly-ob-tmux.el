;;; poly-ob-tmux.el --- Poly-mode for ob-tmux -*- lexical-binding: t; -*-

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Poly-mode for ob-tmux.
;;
;; Heavily inspired by 'poly-org-mode'
;;

;;; Code:


(require 'polymode)
(require 'org)
(require 'org-src)

(defun poly-tmux-mode-matcher ()
  (let ((case-fold-search t))
    (when (re-search-forward "#\\+begin_\\(src\\|example\\|export\\) tmux+.+:lang \\(.*+\\)" (point-at-eol) t)
      (let ((lang (match-string-no-properties 2)))
        (or (cdr (assoc lang org-src-lang-modes))
            lang)))))

(defvar ess-local-process-name)
(defun poly-tmux-convey-src-block-params-to-inner-modes (_ this-buf)
  "Move src block parameters to innermode specific locals.
Used in :switch-buffer-functions slot."
  (cond
   ((derived-mode-p 'ess-mode)
    (with-current-buffer (pm-base-buffer)
      (let* ((params (nth 2 (org-babel-get-src-block-info t)))
             (session (cdr (assq :session params))))
        (when (and session (org-babel-comint-buffer-livep session))
          (let ((proc (buffer-local-value 'ess-local-process-name
                                          (get-buffer session))))
            (with-current-buffer this-buf
              (setq-local ess-local-process-name proc)))))))))

(defun poly-ctrl-c-ctrl-c (beg end msg)
  "blah"
  (org-ctrl-c-ctrl-c)
  )


(define-hostmode poly-tmux-hostmode
  :mode 'org-mode
  :protect-syntax nil
  :protect-font-lock nil)

(define-auto-innermode poly-tmux-innermode
  :fallback-mode 'host
  :head-mode 'host
  :tail-mode 'host
  :head-matcher "^[ \t]*#\\+begin_\\(src\\|example\\|export\\) tmux .*\n"
  :tail-matcher "^[ \t]*#\\+end_\\(src\\|example\\|export\\)"
  :mode-matcher #'poly-tmux-mode-matcher
  :head-adjust-face nil
  :switch-buffer-functions '(poly-tmux-convey-src-block-params-to-inner-modes)
  :body-indent-offset 'org-edit-src-content-indentation
  :indent-offset 'org-edit-src-content-indentation)

;;;###autoload  (autoload 'poly-tmux-mode "poly-tmux")
(define-polymode poly-tmux-mode
  :hostmode 'poly-tmux-hostmode
  :innermodes '(poly-tmux-innermode)
  (setq polymode-eval-region-function #'poly-ctrl-c-ctrl-c)
  (define-key poly-tmux-mode-map (kbd "C-c C-c") 'polymode-eval-chunk)

  (setq-local org-src-fontify-natively t)
  (setq-local polymode-run-these-before-change-functions-in-other-buffers
              (append '(org-before-change-function
                        org-element--cache-before-change
                        org-table-remove-rectangle-highlight)
                      polymode-run-these-before-change-functions-in-other-buffers))
  (setq-local polymode-run-these-after-change-functions-in-other-buffers
              (append '(org-element--cache-after-change)
                      polymode-run-these-after-change-functions-in-other-buffers))
  )

(provide 'poly-ob-tmux)

;;; poly-ob-tmux.el ends here
