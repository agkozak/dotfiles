;; ~/.emacs.d/init.el
;;
;; https://github.com/agkozak/dotfiles

(require 'package)

;; Don't have quelpa use melpa
(setq quelpa-checkout-melpa-p nil)

;; List the packages you want
(setq package-list '(evil
		     evil-leader
		     evil-commentary
		     exec-path-from-shell
		     quelpa))

;; Add Melpa as the default Emacs Package repository
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
		    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives '("gnu" . (concat proto "://elpa.gnu.org/packages/")))))

;; Activate all the packages (in particular autoloads)
(package-initialize)

;; Update your local package index
(unless package-archive-contents
  (package-refresh-contents))

;; Install all missing packages
(dolist (package package-list)
  (unless (package-installed-p package)
    (package-install package)))

(require 'evil)
(evil-mode t)

(require 'evil-leader)
(global-evil-leader-mode)
(evil-leader/set-leader "\\")
(evil-leader/set-key
  "b" 'switch-to-buffer
  "w" 'save-buffer)

;; (require 'exec-path-from-shell)
;; (exec-path-from-shell-initialize)

(require 'evil-commentary)
(evil-commentary-mode)

;; High-contrast Zenburn
(quelpa '(zenburn-theme :repo "holomorph/emacs-zenburn" :fetcher github))
(require 'zenburn-theme)

;; Support for Vim modelines
(quelpa '(vim-modeline :repo "cinsk/emacs-vim-modeline" :fetcher github))
(require 'vim-modeline)

;; Suppress echoing in term and ansi-term (tmux-related)
(setq comint-process-echoes t)

;; Starting term and ansi-term in Emacs mode fixes zsh vi mode
(evil-set-initial-state 'term-mode 'emacs)

;; Line numbers padded with one space
(global-linum-mode t)
(setq linum-format "%d ")

(byte-recompile-directory (expand-file-name "~/.emacs.d") 0)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages (quote (evil-leader evil))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
