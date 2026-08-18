;;; to enable emacs server. set the ALTERNATE_EDITOR variable instead of this?
;;;(setq server-socket-dir "/run/user/1000/emacs/")
;;;(server-start)

;;; could prob place these settings somewhere else idk
(add-hook 'prog-mode-hook 'global-display-line-numbers-mode)
(setq display-line-numbers-type 'visual)

;;; disable error beep on windows
(setq visible-bell 1)

;; for preferredd M-x autocomplete, set icomplete fido-mode & fido-vertical-mode t
;; something seems to reset customizations for these?

;;; packages
(add-to-list 'load-path "~/.emacs.d/packages")
(require 'package)
(add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/") t)
;;; highlight current line, preserving foreground colours(syntax highlighting)
(require 'highlight-current-line)
;;; customize using ~M-x customize-group highlight-current-line <RET>~
(require 'notifications)

;;; disable suspending frame with C-z
(put 'suspend-frame 'disabled t)

;;; hide bars
(tool-bar-mode 0)
(menu-bar-mode 0)

(global-set-key (kbd "C-x B") 'switch-to-buffer-other-window)

;; default font
;; (set-frame-font "JetBrainsMono NFP-12" nil t)

;;;; Org Mode configs
(add-hook 'org-mode-hook #'turn-on-font-lock)
;;; because college week starts on tuesdays
;; (setq org-agenda-start-on-weekday 2)

(setq calendar-week-start-day 0)

;; change all prompts to y or n
(fset 'yes-or-no-p 'y-or-n-p)

;;; Org-mode bindings. These should be accessible everywhere.
(global-set-key (kbd "C-c l") #'org-store-link)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)
(setq org-startup-indented t)
(setq org-adapt-indentation nil)

;;; org mode sets truncate lines to t. use this to set to nil
(add-hook 'org-mode-hook #'toggle-truncate-lines)
;; (add-hook 'org-agenda-mode-hook #'toggle-truncate-lines)
;; truncate lines in agenda view to make it compact
(add-hook 'org-agenda-mode-hook
          (lambda () (setq truncate-lines t)))


;; linux
(setq org-directory "~/org")

;; windows
;; (setq org-directory "~\Documents\org")
(setq org-default-notes-file (concat org-directory "/notes.org"))
(with-eval-after-load 'org
  (setq org-return-follows-link t)
  (setq org-startup-folded t)
  ;; TODO: # is used to avoid compiler warnings.
  ;; look into ways to solve other compiler warnings that pop up
  (bind-key "M-k" #'org-metaup org-mode-map)
  (bind-key "M-j" #'org-metadown org-mode-map)
  (evil-define-minor-mode-key 'normal 'evil-org-mode "M-k" #'org-metaup)
  (evil-define-minor-mode-key 'normal 'evil-org-mode "M-j" #'org-metadown)

  (bind-key "M-K" #'org-shiftmetaup org-mode-map)
  (bind-key "M-J" #'org-shiftmetadown org-mode-map)
  (evil-define-minor-mode-key 'normal 'evil-org-mode "M-K" #'org-shiftmetaup)
  (evil-define-minor-mode-key 'normal 'evil-org-mode "M-J" #'org-shiftmetadown)

  (bind-key "M-l" #'org-metaright org-mode-map)
  (bind-key "M-h" #'org-metaleft org-mode-map)
  (evil-define-minor-mode-key 'normal 'evil-org-mode "M-l" #'org-metaright)
  (evil-define-minor-mode-key 'normal 'evil-org-mode "M-h" #'org-metaleft)
  )

(with-eval-after-load 'org-agenda
  (require 'org-agenda)
  (define-key org-agenda-mode-map (kbd "C-w") #'evil-window-map)
  ;; hjkl for directional movement
  (define-key org-agenda-mode-map (kbd "h") 'left-char)
  (define-key org-agenda-mode-map (kbd "j") 'org-agenda-next-line)
  (define-key org-agenda-mode-map (kbd "k") 'org-agenda-previous-line)
  (define-key org-agenda-mode-map (kbd "l") 'right-char)
  (define-key org-agenda-mode-map (kbd "C-j") 'org-agenda-goto-date)
  ;; move forward one word with w like in vim 
  (define-key org-agenda-mode-map (kbd "w") 'forward-word)
  (define-key org-agenda-mode-map (kbd "W") 'org-agenda-week-view)
  (evil-define-key 'normal org-mode-map (kbd "t") #'org-set-tags-command)
  )
(with-eval-after-load 'evil-maps
  (define-key evil-motion-state-map (kbd "SPC") nil)
  ;;; to allow following links in org mode with <return>
  (define-key evil-motion-state-map (kbd "RET") nil)
  (define-key evil-motion-state-map (kbd "TAB") nil)
  )

;;; open capture templates in insert mode
(add-hook 'org-capture-mode-hook 'evil-insert-state)

;; function for inserting org-capture templates to current cursor (without C-0 prefix)
;; to use, set `entry (function org-capture-at-point)` for capture templates
(defun org-capture-at-point ()
  "Use current buffer and point as capture target."
  (set-buffer (current-buffer))
  (goto-char (point))
  (point))


;;; From gavin freeborn's "Getting Evil in Emacs" video

;;; Startup
;;; PACKAGE LIST
(setq package-archives 
      '(("melpa" . "https://melpa.org/packages/")
        ("elpa" . "https://elpa.gnu.org/packages/")))

;;; BOOTSTRAP USE-PACKAGE
(package-initialize)
(setq use-package-always-ensure t)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile (require 'use-package))

;;; UNDO
;; Vim style undo not needed for emacs 28
(use-package undo-fu)

;;; Vim Bindings
(use-package evil
  :demand t
  :bind (("<escape>" . keyboard-escape-quit))
  :init
  ;; allows for using cgn
  ;; (setq evil-search-module 'evil-search)
  (setq evil-want-keybinding nil)
  ;; no vim insert bindings
  (setq evil-undo-system 'undo-fu)
  :config
  (evil-mode 1))

(require 'org-wild-notifier)
;;; Vim Bindings Everywhere else
(use-package evil-collection
  :after evil
  :config
  (setq evil-want-integration t)
  (evil-collection-init))

;; agenda files
;; if you create new file, delete line that sets this var in custom-set-variables and eval this buffer

;; todo: adjust this for linux, or cross compatible if possible
;; turns out you can just set this to a directory & all files within it get used
;;(setq org-agenda-files
;;      (cl-remove-if (lambda (path)
;;                      (or (string-match-p ".stfolder" path)
;;                          (string-match-p ".stversions" path)
;;                          (and (string-match-p "~\\\\Documents\\\\org\\\\college\\\\5th-sem\\\\" path)
;;                               (not (string= "5th-sem.org" (file-name-nondirectory path))))
;;                          (string= "~\\\\Documents\\\\org\\\\programming\\\\cardsQL\\\\cardsql-notes.org" path)))
;;                    (directory-files-recursively "~\\\\Documents\\\\org\\\\" "\\.org$" t)))

;; (setq org-agenda-files (directory-files-recursively "~/org/agenda" "\\.org$"))


(global-set-key (kbd "C-x B") 'switch-to-buffer-other-window)
;;; pomodoro shortcut. same command starts/ends pomo

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(alert-default-style 'notifications)
 '(auto-save-visited-mode t)
 '(blink-cursor-mode nil)
 '(custom-enabled-themes '(kaolin-shiva))
 '(custom-safe-themes
   '("e4a441d3cea911e8ef36de2eaed043cbe2079484c44c3f2bbab67a46f863a9f6"
     "e266d44fa3b75406394b979a3addc9b7f202348099cfde69e74ee6432f781336" default))
 '(display-line-numbers-type 'visual)
 '(evil-toggle-key "")
 '(evil-undo-system 'undo-redo)
 '(fast-but-imprecise-scrolling nil)
 '(fido-mode t)
 '(fido-vertical-mode t)
 '(fill-column 80)
 '(global-auto-revert-mode t)
 '(good-scroll-mode nil)
 '(helm-minibuffer-history-key "M-p")
 '(help-window-select t)
 '(highlight-current-line-globally nil nil (highlight-current-line))
 '(icomplete-mode t)
 '(kaolin-theme-linum-hl-line-style t)
 '(kaolin-themes-hl-line-colored t)
 '(org-agenda-files
   '("~/org/agenda/diary.org" "/home/sujal/org/agenda/gtd.org"
     "/home/sujal/org/agenda/skills-home.org"
     "/home/sujal/org/college/8th-sem/8th-sem.org"
     "/home/sujal/org/college/7th-sem/7th-sem.org"
     "/home/sujal/org/agenda/Getting Started with Orgzly.org"
     "/home/sujal/org/agenda/glohmed.org"
     "/home/sujal/org/agenda/phone-only.org" "/home/sujal/org/agenda/rice.org"
     "/home/sujal/org/agenda/todo-list.org"))
 '(org-agenda-sorting-strategy
   '((agenda time-up priority-down category-keep)
     (todo priority-down category-keep) (tags priority-down category-keep)
     (search category-keep)))
 '(org-agenda-start-on-weekday 0)
 '(org-agenda-tags-column 0)
 '(org-agenda-time-grid
   '((require-timed) (600 1100 1700 1930 2200) " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"))
 '(org-agenda-timegrid-use-ampm t)
 '(org-agenda-use-time-grid t)
 '(org-agenda-window-setup 'reorganize-frame)
 '(org-capture-templates
   '(("t" "Todo (Inbox)" entry (id "cad112ea-2010-44f3-9908-a140f4f0f018")
      "* TODO %? \12# recorded on: %u\12- [ ] takes < 2mins? do now (y/n)\12- [ ] has subtasks? (y/n)\12  + [ ] define MVP, optional tasks\12  + [ ] refile to Projects"
      :empty-lines-after 1)
     ("d" "diary log" table-line (id "7917cd56-d7d6-4409-8977-a4170468c155")
      "| %u | %? | " :jump-to-captured t)
     ("i" "Idea")
     ("cd" "Daily docs (remmeber to use C-0 prefix)" entry
      #'org-capture-at-point
      "* TODO %u docs:  %?#context/topic\12:PROPERTIES:\12:Copy_num: rough8-copy1 (HCOE notebook)\12:Page_range: \12:END:\12** Tasks (if any)"
      :empty-lines-after 1)
     ("ib" "Blog post idea" entry (id "8326e378-80a0-488f-82ed-4f947e774f2a")
      "* Blog post idea: %?\12got idea on: %u")
     ("iw" "wp docs site idea" entry (id "84544fce-06b6-4ec3-8850-daf807ddacc3")
      "* %?\12if its a plugin, refile to [[file:~/org/notes/extra-learning.org::*WordPress][extra-learning.org]]")
     ("c" "College")
     ("cf" "Flash-card" entry #'org-capture-at-point
      "* %? :drill:\12# \12** answer \12** extra info" :empty-lines-after 1)
     ("ip" "problem-solution app (Pieter levels book )" entry
      (id "0867b18b-0c8f-42b9-828a-fb69453a3db5")
      "* %u\12- problem: %?# some title\12- technical solution:"
      :jump-to-captured t)
     ("cl" "Lab Report (remmeber to use M-x make-directory if needed)" plain
      (file buffer-name)
      "# for project documents, use addtional latex styles used in final-report file\12:edit-this:\12#+EXPORT_FILE_NAME: %?-report\12#+PROPERTY: header-args :eval no-export\12# don't prompt to evaluate code blocks while exporting\12#+OPTIONS: toc:nil ^:{}\12# set toc below instead of here\12# 2nd option exports subscripts only when _{} is used\12#+LATEX_HEADER: \\graphicspath{{~/programming/college-files/assets/images/}}\12\12# !!!!!!!!!!!!!          only edit this section       !!!!!!\12#+LATEX_HEADER: \\def\\subjectNum{1}\12# 1: DBProg\12# 2: Media\12# 3: none\12# 4: none\12# 5: none\12\12#+LATEX_HEADER: \\def\\labNum{2}\12#+LATEX_HEADER: \\def\\labTitle{Escape ampersand \\&}\12#+LATEX_HEADER: \\def\\yearSem{IV/VIII}\12#+LATEX_HEADER: \\newif \\iftoc\12# !!!!!!!!!!!!           set toc here by uncommenting option\12# \\toctrue    \12\\tocfalse\12:end:\12\12#+INCLUDE: \"~/programming/college-files/assets/template.org\" :lines \"27-\"\12* Objectives\12* Introduction \12* Lab Work\12** Explanation\12* Output\12* Conclusion\12")
     ("s" "search for (later) " item (id "5a913987-7bc5-4aeb-bf08-75499f95f6c8")
      "%U  %?" :empty-lines-before 1)
     ("i" "img, inline source code")
     ("im" "Image for Org-mode / Latex" plain #'org-capture-at-point
      "#+CAPTION: %? # Describe the image\12#+attr_latex: :width 0.7\\textwidth\12#+attr_org: :height 200px\12# to insert img w/ autocomplete, use C-c C-l, file: RET\12[[file:img/example.png]]\12# place this between img & section to prevent img moving below section\12#+LATEX:\\FloatBarrier"
      :empty-lines 1)
     ("is" "Inline source code block (remember to use C-0 prefix)" plain
      #'org-capture-at-point "src_%?lang[:exports code]{insertCodeHere}\\\\"
      :jump-to-captured t)))
 '(org-cite-export-processors '((t basic nil nil)))
 '(org-clock-idle-time nil)
 '(org-clock-mode-line-total 'current)
 '(org-drill-leech-method 'warn)
 '(org-drill-maximum-items-per-session 20)
 '(org-export-allow-bind-keywords t)
 '(org-export-backends '(ascii html icalendar latex md odt))
 '(org-goto-interface 'outline-path-completion)
 '(org-habit-following-days 1)
 '(org-habit-graph-column 82)
 '(org-habit-preceding-days 5)
 '(org-habit-show-done-always-green t)
 '(org-habit-show-habits t)
 '(org-habit-show-habits-only-for-today nil)
 '(org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id)
 '(org-image-actual-width nil)
 '(org-latex-engraved-theme 'kaolin-valley-light)
 '(org-latex-logfiles-extensions
   '("tex" "aux" "bcf" "log" "blg" "fdb_latexmk" "fls" "ist" "glsdefs" "glo" "acn"
     "figlist" "idx" "nav" "out" "pygstyle" "pygtex" "ptc" "run.xml" "snm" "toc"
     "vrb" "xdv" "pdf_tex" "lof" "lot" "acr" "alg" "gls" "glg"))
 '(org-latex-packages-alist nil)
 '(org-latex-src-block-backend 'engraved)
 '(org-latex-toc-command "\\tableofcontents \\clearpage")
 '(org-list-allow-alphabetical t)
 '(org-log-done nil)
 '(org-log-into-drawer t)
 '(org-log-repeat nil)
 '(org-modules
   '(ol-bbdb ol-bibtex ol-docview ol-doi ol-eww ol-gnus org-habit ol-info ol-irc
	     ol-mhe ol-rmail ol-w3m))
 '(org-notifications-style 'notifications)
 '(org-notifications-which-agenda-files 'agenda-only)
 '(org-num-skip-unnumbered t)
 '(org-pomodoro-expiry-time 90)
 '(org-pomodoro-keep-killed-pomodoro-time t)
 '(org-pomodoro-length 45)
 '(org-pomodoro-long-break-frequency 3)
 '(org-pomodoro-long-break-length 30)
 '(org-pomodoro-manual-break t)
 '(org-pomodoro-short-break-length 6)
 '(org-pretty-entities t)
 '(org-preview-latex-default-process 'dvisvgm)
 '(org-refile-targets '((org-agenda-files :maxlevel . 2)))
 '(org-refile-use-outline-path 'file)
 '(org-structure-template-alist
   '(("a" . "export ascii") ("c" . "center") ("C" . "comment") ("e" . "example")
     ("E" . "export") ("h" . "export html") ("l" . "export latex")
     ("q" . "quote") ("s" . "src") ("S1" . "src sql :results raw :exports both")
     ("S2" . "src sql :results silent") ("v" . "verse")))
 '(org-tag-alist
   '(("office" . 111) ("personal" . 112) ("college" . 99) ("drill" . 100)
     ("exam_q" . 113) ("hide_in_agenda" . 104) ("gtd_next" . 110) ("2_min" . 50)
     ("gtd_waiting" . 119)))
 '(org-tags-column -58)
 '(org-tags-exclude-from-inheritance '("hide_in_agenda"))
 '(org-timestamp-custom-formats '("%y-%m-%d %a" . "%y-%m-%d %a %H:%M"))
 '(org-use-sub-superscripts '{})
 '(org-wild-notifier-alert-time '(10 1))
 '(org-wild-notifier-day-wide-alert-times nil)
 '(org-wild-notifier-keyword-whitelist nil)
 '(org-wild-notifier-mode t)
 '(package-selected-packages
   '(alert amx auto-complete citeproc citeproc-org clues-theme engrave-faces evil
	   evil-collection flx-ido good-scroll kaolin-themes lambda-themes
	   ligature ob-sql-mode org-drill org-fragtog org-pomodoro org-re-reveal
	   org-superstar org-wild-notifier php-mode plantuml-mode ultra-scroll
	   undo-fu use-package))
 '(pixel-scroll-mode nil)
 '(pixel-scroll-precision-mode t)
 '(scroll-conservatively 10)
 '(server-stop-automatically 'empty)
 '(set-mark-command-repeat-pop t)
 '(split-width-threshold 80)
 '(text-quoting-style 'grave)
 '(truncate-lines nil)
 '(ultra-scroll-mode nil))

 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.

;; backup 
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "JetBrains Mono" :foundry "JB" :slant normal :weight normal :height 120 :width normal))))
 '(highlight ((t (:background "#1B183D" :foreground "Old Lace"))))
 '(highlight-current-line-face ((t (:background "LightSkyBlue3"))))
 '(hl-line ((t (:extend t :background "#1B183D" :foreground "nil"))))
 '(org-habit-clear-face ((t (:background "#554151")))))


(require 'kaolin-themes)
;; (load-theme 'kaolin-dark t)
;; Apply treemacs customization for Kaolin themes, requires the all-the-icons package.
(kaolin-treemacs-theme)
;;; org-superstar-mode customization

;;; Titles and Sections
;; hide #+TITLE:
(setq org-hidden-keywords '(title))
(with-eval-after-load 'org-faces 
  ;; set basic title font
  (set-face-attribute 'org-level-8 nil :weight 'bold :inherit 'default)
  ;; Low levels are unimportant => no scaling
  (set-face-attribute 'org-level-7 nil :inherit 'org-level-8)
  (set-face-attribute 'org-level-6 nil :inherit 'org-level-8)
  (set-face-attribute 'org-level-5 nil :inherit 'org-level-8)
  (set-face-attribute 'org-level-4 nil :inherit 'org-level-8)
  
  (set-face-attribute 'org-level-3 nil :inherit 'org-level-8 :height 1.2) 
  (set-face-attribute 'org-level-2 nil :inherit 'org-level-8 :height 1.34) 
  (set-face-attribute 'org-level-1 nil :inherit 'org-level-8 :height 1.528) ;\LARGE
  ;; Only use the first 4 styles and do not cycle.
  (setq org-cycle-level-faces nil)
  (setq org-n-level-faces 4)
  ;; Document Title, (\huge)
  (set-face-attribute 'org-document-title nil
		      :height 2.074
		      :foreground 'unspecified
		      :inherit 'org-level-8)
)

;;; Basic Setup
;; Auto-start Superstar with Org
(add-hook 'org-mode-hook
          (lambda ()
            (org-superstar-mode 1)))

;;; PlantUML inside org-mode
 (setq org-plantuml-jar-path (expand-file-name "/home/sujal/.emacs.d/packages/plantuml-1.2023.11.jar"))
;; (setq org-plantuml-jar-path (expand-file-name "c:/Users/sujal/.emacs.d/packages/plantuml-1.2023.11.jar"))
(add-to-list 'org-src-lang-modes '("plantuml" . plantuml))  
;; idk this above one was being used before this update
 (org-babel-do-load-languages 'org-babel-load-languages '((plantuml . t)))

;;; Bibliography/ IEEE style references 
(require 'citeproc)
(require 'citeproc-org)
(require 'oc-csl)
(require 'oc-bibtex)



;; Use 'texliveonfly' for automatic package installation during LaTeX export
;; (setq org-latex-pdf-process '("latexmk -shell-escape -bibtex -pdf %f"))

;; Optional: Specify texliveonfly as the default TeX compiler
;; (setq org-latex-compiler "texliveonfly")

; default backup
;; run twice to prevent errors like empty toc
;; makeglossaries required for list of glossaries, acronyms in report
;; latex-related binaries aren't accessible in emacs despite being in path so provide absolute path
;; if errors, change pdflatex path here or replace absolute path w/ just relative
(setq org-latex-pdf-process
      '("~/bin/pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"
        "~/bin/makeglossaries %b"
        "~/bin/pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"
        "~/bin/pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))

;; (setq org-latex-pdf-process
;;       '("~/bin/pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"
;;         "~/bin/pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"
;;         "~/bin/pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))

;; cursor shapes
(setq evil-emacs-state-cursor '("red" vbar))
(setq evil-normal-state-cursor '("tan3" box))
(setq evil-insert-state-cursor '("Old Lace" bar))
(setq evil-visual-state-cursor '("tan3" nil))

;; delete lingering old theme settings when setting new
(defun override-theme (arg)
  (interactive)
  (while custom-enabled-themes
    (disable-theme (car custom-enabled-themes)))
  (load-theme arg t))
;; set theme here
;;(override-theme 'leuven-dark)

;;; work-around for org-ctags obnoxious behavior (calls visit-tags-table() when opening internal links)
(with-eval-after-load 'org-ctags (setq org-open-link-functions nil))

(defun my-org-reset-checkbox-state-maybe ()
  "Reset all checkboxes in an entry if the `RESET_CHECK_BOXES' property is set"
  (interactive "*")
  (if (org-entry-get (point) "RESET_CHECK_BOXES")
      (org-reset-checkbox-state-subtree)))

(defun my-org-reset-checkbox-when-done ()
  (when (member org-state org-done-keywords) ;; org-state dynamically bound in org.el/org-todo
    (my-org-reset-checkbox-state-maybe)))

(add-hook 'org-after-todo-state-change-hook 'my-org-reset-checkbox-when-done)

;; package for always previewing latex & turning off previews when cursor is over preview
(add-hook 'org-mode-hook 'org-fragtog-mode)

;; Customize LaTeX preview font size
(setq org-format-latex-options
      (plist-put org-format-latex-options :scale 1.35)) ; Adjust the scale value as needed

;; syntax highlighting for inline source blocks in org mode
(defun org+-fontify-inline-src-code (limit)
  "Match inline source blocks from point to LIMIT."
  (when (re-search-forward "\\_<src_\\([^ \t\n[{]+\\)[{[]" limit t) ;; stolen from `org-element-inline-src-block-parser'
    ;; This especially clarifies that the square brackets are optional.
    (let ((beg (match-beginning 0))
      pt
      (lang-beg (match-beginning 1))
      (lang-end (match-end 1))
      header-args-beg header-args-end
      code-beg code-end)
      (setq pt (goto-char lang-end))
      (when (org-element--parse-paired-brackets ?\[)
    (setq header-args-beg pt
          header-args-end (point)
          pt (point)))
      (when (org-element--parse-paired-brackets ?\{)
    (setq code-beg pt
          code-end (point))
    (set-match-data
     (list beg (point)
           beg lang-beg
           lang-beg
           lang-end
           header-args-beg
           header-args-end
           code-beg
           code-end
           (current-buffer)))
    code-end))))

(defun org+-config-fontify-inline-src-code ()
  "Fontify inline source code, such as src_html[:exports code]{<em>to be emphased</em>}."
  (font-lock-add-keywords nil
              '((org+-fontify-inline-src-code
                 (1 '(:foreground "black" :weight normal :height 10) t) ; src_ part
                 (2 '(:foreground "cyan" :weight bold :height 75 :underline "red") t) ; "lang" part.
                 (3 '(:foreground "#555555" :height 70) t) ; [:header arguments] part.
                 (4 'org-code t) ; "code..." part.
                 ))
              'append))

(add-hook 'org-mode-hook #'org+-config-fontify-inline-src-code)
(setq org-latex-src-block-backend 'engraved)

;;; pomodoro shortcut. same command starts/ends pomo 
(eval-after-load 'org
  '(progn
     (define-key org-mode-map (kbd "C-c C-x C-p") 'org-pomodoro)))

(setq org-agenda-custom-commands
      '(("a" "Default weekly Agenda (custom)"
	 ((agenda "" (
		      (org-agenda-skip-function #'my/org-agenda-skip-habits)
		      ))
	  )
	 ;; need to fix this so that :docs: is ignored as well
	 ((org-agenda-tag-filter-preset '("-drill" "-docs"))))
	("d" "Daily + GTD Next (filtered)"
	 ((agenda ""
		  ((org-agenda-span 1)
		   (org-agenda-overriding-header "📅 Today")
		   ;; deadlines will be shown separately
		   (org-deadline-warning-days 0)
		   (org-agenda-skip-function #'my/org-skip-hidden-or-done)))
	  (agenda ""
		  (
		   (org-agenda-overriding-header "‼️ Upcoming deadlines:")
		   (org-agenda-span 7)  ;; use this to limit number of days whose deadline shown in advance
		   (org-agenda-start-day "+1d") ;; deadlines after today.
		   (org-deadline-warning-days 0) ;; show deadlines only for deadline date, not before
		   (org-agenda-entry-types '(:deadline))
		   (org-agenda-show-all-dates nil)
		   ))
	  (tags "gtd_next"
		((org-agenda-overriding-header "🚀 GTD Next Actions")
		 (org-agenda-skip-function #'my/org-skip-hidden-or-done)))))
	("i" "GTD Inbox filtered"
	 tags "gtd_inbox"
	 ((org-agenda-overriding-header "📥 GTD Inbox")
	  (org-agenda-skip-function #'my/org-skip-hidden-or-done)
	  ))
	("2" "2 min tasks. Do if bored"
	 tags "2_min"
	 (
	  (org-agenda-skip-function #'my/org-skip-hidden-or-done)
	  ))
	("b" "Bored"
	 ((tags "bored"))
	  (org-agenda-skip-function #'my/org-skip-hidden-or-done)
	 ((org-agenda-overriding-header "Do these if feeling bored"))
	 )
	("o" "Today only (old)" 
	 (
	  (agenda ""
		  ((org-agenda-span 1)
		   (org-deadline-warning-days 0)
		   (org-agenda-skip-function #'my/org-skip-hidden-or-done)
		   ))
	  (agenda ""
		  ((org-agenda-span 3)
		   (org-agenda-start-day "+1d")
		   (org-deadline-warning-days 0)
		   (org-agenda-entry-types '(:deadline))
		   (org-agenda-overriding-header "Deadlines coming up:")))
	  (todo "READING" 
		((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
		 (org-agenda-overriding-header "Reading:")))
	  ;; (agenda ""
	  ;; 	  ((org-agenda-skip-function '(my-org-skip-overdue))
	  ;; 	   (org-agenda-overriding-header "Overdue Items:"))
	  ;; 	  )
	  )
	 ;; being filtered out from above
	 ;; ((org-agenda-tag-filter-preset '("-drill" "-hide_in_agenda")))
	 )
	))

;; used in custom agenda commands above
(defun my/org-skip-hidden-or-done ()
  (let ((tags (org-get-tags nil t)))
    (when (or (member "hide_in_agenda" tags)
              (member "drill" tags)
              (org-entry-is-done-p))
      (outline-next-heading)
      (point)
      )))
(defun my/org-agenda-skip-habits ()
  "Skip agenda entries that are habits."
  (let ((style (org-entry-get (point) "STYLE")))
    (when (and style (string= style "habit"))
      (or (outline-next-heading) (point-max)))))


;(use-package alert
;  :config
;  ;; Add the windows desktop notifications if on windows
;  (when (eq system-type 'windows-nt)
;    (alert-define-style
;     'windows-desktop-notification-style
;     :title "Windows Desktop Notification style"
;     :notifier
;     (lambda (info)
;       (let ((notif-id (w32-notification-notify :title (plist-get info :title) :body (plist-get info :message))))
;         ;; Close it after 5 seconds (no new notification can be sent if left unclosed)
;         (run-with-timer 7 nil `(lambda() (w32-notification-close ,notif-id))))))
;    (setq alert-default-style 'windows-desktop-notification-style)))

;; don't think this works
(defun my-org-skip-overdue ()
  "Skip entries scheduled after today."
  (let ((now (time-to-days (current-time))))
    (while (and (not (eobp))
                (let* ((scheduled (org-entry-get (point) "SCHEDULED"))
                       (scheduled-time (if scheduled (time-to-days (org-time-string-to-time scheduled)))))
                  (and scheduled (<= scheduled-time now))))
      (outline-next-heading))))

(setopt use-short-answers t)   ;; Since Emacs 29, `yes-or-no-p' will use `y-or-n-p'


;; maximize Emacs at startup on windows
;; disable when using glaze-wm or komorebi because maximizing will cause fullscreen (& hide bar)
;; (w32-send-sys-command #xf030)

;; ligatures (depends on ligatures package)
;; Enable the www ligature in every possible major mode
(ligature-set-ligatures 't '("www"))

;; Enable ligatures in programming & org modes                                                           
(ligature-set-ligatures '(prog-mode org-mode) '("www" "**" "***" "**/" "*>" "*/" "\\\\" "\\\\\\" "{-" "::"
                                     ":::" ":=" "!!" "!=" "!==" "-}" "----" "-->" "->" "->>"
                                     "-<" "-<<" "-~" "#{" "#[" "##" "###" "####" "#(" "#?" "#_"
                                     "#_(" ".-" ".=" ".." "..<" "..." "?=" "??" ";;" "/*" "/**"
                                     "/=" "/==" "/>" "//" "///" "&&" "||" "||=" "|=" "|>" "^=" "$>"
                                     "++" "+++" "+>" "=:=" "==" "===" "==>" "=>" "=>>" "<="
                                     "=<<" "=/=" ">-" ">=" ">=>" ">>" ">>-" ">>=" ">>>" "<*"
                                     "<*>" "<|" "<|>" "<$" "<$>" "<!--" "<-" "<--" "<->" "<+"
                                     "<+>" "<=" "<==" "<=>" "<=<" "<>" "<<" "<<-" "<<=" "<<<"
                                     "<~" "<~~" "</" "</>" "~@" "~-" "~>" "~~" "~~>" "%%"))

(global-ligature-mode 't)
(add-hook 'org-mode-hook #'display-fill-column-indicator-mode)
(prefer-coding-system 'utf-8)
;; org-re-reveal
(require 'org-re-reveal)
(setq org-re-reveal-root "https://cdn.jsdelivr.net/npm/reveal.js")
(setq org-re-reveal-revealjs-version "4")

;; unbind C-w in agenda view to allow switching windows easily
(add-hook 'agenda-view-mode-hook
          (lambda ()
	    (define-key agenda-view-mode-map "\C-w" nil)
	    ))
(defun my-org-mode-keybindings ()
  (define-key org-mode-map "\C-w\C-w" 'evil-window-next))
;; (add-hook 'org-mode-hook (lambda () (define-key org-mode-map "\C-w\C-w" 'evil-window-next)))

;; make calendar overflow instead of wrap. useful when using split windows
(defun my-calendar-hook ()
  "Turn line truncation on."
  (toggle-truncate-lines 1))

(add-hook 'calendar-mode-hook #'my-calendar-hook)

;; required so that pdflatex is in emacs' PATH
;; use whatever path that contains pdflatex (~/bin is for miktex)
(setenv "PATH" (concat "/home/sujal/bin" ":" (getenv "PATH")))
(setq exec-path (append exec-path '("/home/sujal/bin")))

; (use-package ultra-scroll
;   :vc (:url "https://github.com/jdtsmith/ultra-scroll") ; For Emacs>=30
;   :init
;   (setq scroll-conservatively 5 ; or whatever value you prefer, since v0.4
;         scroll-margin 0)        ; important: scroll-margin>0 not yet supported
;   :config
;   (ultra-scroll-mode 1))
; (add-hook 'ultra-scroll-hide-functions 'hl-line-mode)

;; 3rd party smooth scroll plugin because built-in smooth scrolling doesn't work on windows 
;; (good-scroll-mode 1) 

;; for college revising. delete after college fin
(defun cards-8th-sem ()
  "Switch to buffer '8th-sem.org', require org-drill, and open org-drill directory."
  (interactive)
  (switch-to-buffer "8th-sem.org")
  (require 'org-drill)
  (org-drill-directory))
