;;; arc-mode.el --- simple editing of archives  -*- lexical-binding: t; -*-
;;			Arc	Lzh	Zip	Zoo	Rar	7z	Ar
;;			--------------------------------------------------
;; View listing		Intern	Intern	Intern	Intern	Y	Y	Y
;; Extract member	Y	Y	Y	Y	Y	Y	Y
;; Save changed member	Y	Y	Y	Y	N	Y	Y
;; Add new member	N	N	N	N	N	N	N
;; Delete member	Y	Y	Y	Y	N	Y	N
;; Rename member	Y	Y	N	N	N	N	N
;; Chmod		-	Y	Y	-	N	N	N
;; Chown		-	Y	-	-	N	N	N
;; Chgrp		-	Y	-	-	N	N	N
(eval-when-compile (require 'cl-lib))

  :type 'directory)
  :type 'regexp)
  :type 'hook)
                 (const :tag "Show the archive summary" nil)))

(defcustom archive-hidden-columns '(Ids)
  "Columns hidden from display."
  :version "28.1"
  :type '(set (const Mode)
              (const Ids)
              (const Date&Time)
              (const Ratio)))

(defconst archive-alternate-hidden-columns '(Mode Date&Time)
  "Columns hidden when `archive-alternate-display' is used.")


(defgroup archive-arc nil
  "ARC-specific options to archive."
  :group 'archive)

			(string :format "%v"))))
			(string :format "%v"))))
			(string :format "%v"))))
(defgroup archive-lzh nil
  "LZH-specific options to archive."
  :group 'archive)

			(string :format "%v"))))
			(string :format "%v"))))
			(string :format "%v"))))
(defgroup archive-zip nil
  "ZIP-specific options to archive."
  :group 'archive)

		       (string :format "%v"))))
		       (string :format "%v"))))
		       (string :format "%v"))))
		       (string :format "%v"))))
  :version "27.1")
(defgroup archive-zoo nil
  "ZOO-specific options to archive."
  :group 'archive)

			(string :format "%v"))))
			(string :format "%v"))))
			(string :format "%v"))))
(defgroup archive-7z nil
  "7Z-specific options to archive."
  :group 'archive)

		       (string :format "%v"))))
		       (string :format "%v"))))
		       (string :format "%v"))))
(defvar-local archive-file-list-start nil "Position of first contents line.")
(defvar-local archive-file-list-end nil "Position just after last contents line.")
(defvar-local archive-proper-file-start nil "Position of real archive's start.")
(defvar-local archive-local-name nil "Name of local copy of remote archive.")
    (define-key map "C" 'archive-copy-file)
    (define-key map [menu-bar immediate view]
      '(menu-item "Copy This File" archive-copy-file
                  :help "Copy file at cursor to another location"))
(defvar-local archive-file-name-indent nil "Column where file names start.")
(defvar-local archive-remote nil "Non-nil if the archive is outside file system.")
(defvar-local archive-member-coding-system nil "Coding-system of archive member.")
(defvar-local archive-alternate-display nil
(defvar-local archive-subfile-mode nil
  "Non-nil in archive member buffers.
Its value is an `archive--file-desc'.")
(defvar-local archive-file-name-coding-system nil)
(cl-defstruct (archive--file-desc
               (:constructor nil)
               (:constructor archive--file-desc
                ;; ext-file-name and int-file-name are usually `eq'
                ;; except when int-file-name is the downcased
                ;; ext-file-name.
                (ext-file-name int-file-name mode size time
                               &key pos ratio uid gid)))
  ext-file-name int-file-name
  (mode nil  :type integer)
  (size nil  :type integer)
  (time nil  :type string)
  (ratio nil :type string)
  uid gid
  pos)

;; Features in formats:
;;
;; ARC: size, date&time (date and time strings internally generated)
;; LZH: size, date&time, mode, uid, gid (mode, date, time generated, ugid:int)
;; ZIP: size, date&time, mode (mode, date, time generated)
;; ZOO: size, date&time (date and time strings internally generated)
;; AR : size, date&time, mode, user, group (internally generated)
;; RAR: size, date&time, ratio (all as strings, using `lsar')
;; 7Z : size, date&time (all as strings, using `7z' or `7za')
;;
;; LZH has alternate display (with UID/GID i.s.o MODE/DATE/TIME

(defvar-local archive-files nil
  "Vector of `archive--file-desc' objects.")
    (insert (if (and (integerp elt) (>= elt 128))
                (decode-char 'eight-bit elt)
              elt))))
(define-obsolete-function-alias 'archive-int-to-mode
  'file-modes-number-to-symbolic "28.1")

(defun archive-calc-mode (oldmode newmode)
OLDMODE will be modified accordingly just like chmod(2) would have done."
  ;; FIXME: Use `file-modes-symbolic-to-number'!
  (if (string-match "\\`0[0-7]*\\'" newmode)
      (logior (logand oldmode #o177000) (string-to-number newmode 8))
    (file-modes-symbolic-to-number newmode oldmode)))
                     "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"]
                    (1- month))
	  (if (and (archive--file-desc-p item)
	           (let ((mode (archive--file-desc-mode item)))
	             (zerop (logand 16384 mode))))
		(user-error "Entry is not a regular member of the archive"))))
      (funcall (or (default-value 'major-mode) #'fundamental-mode))
	(setq-local archive-subtype type)
	(add-function :around (local 'revert-buffer-function)
	              #'archive--mode-revert)
	(add-hook 'write-contents-functions #'archive-write-file nil t)
        (setq-local truncate-lines t)
	(setq-local require-final-newline nil)
	(setq-local local-enable-local-variables nil)
	(setq-local file-precious-flag t)
	(setq-local archive-read-only
		    (or (not (file-writable-p (buffer-file-name)))
		        (and archive-subfile-mode
		             (string-match file-name-invalid-regexp
				           (archive--file-desc-ext-file-name
				            archive-subfile-mode)))))
	(setq major-mode #'archive-mode)
    (add-hook 'change-major-mode-hook #'archive-desummarize nil t)
(cl-defstruct (archive--file-summary
               (:constructor nil)
               (:constructor archive--file-summary (text name-start name-end)))
  text name-start name-end)

  ;; Here we assume that they all start at the same column.
  (setq archive-file-name-indent
        ;; FIXME: We assume chars=columns (no double-wide chars and such).
        (if files (archive--file-summary-name-start (car files)) 0))
   (mapconcat
    (lambda (fil)
      ;; Using `concat' here copies the text also, so we can add
      ;; properties without problems.
      (let ((text (concat (archive--file-summary-text fil) "\n")))
        (add-text-properties
         (archive--file-summary-name-start fil)
         (archive--file-summary-name-end fil)
         '(mouse-face highlight
           help-echo "mouse-2: extract this file into a buffer")
         text)
        text))
    files
    ""))
  (setq-local archive-hidden-columns
              (if archive-alternate-display
                  archive-alternate-hidden-columns
                (eval (car (or (get 'archive-hidden-columns 'customized-value)
                               (get 'archive-hidden-columns 'standard-value)))
                      t)))

(defun archive-hideshow-column (column)
  "Toggle visibility of COLUMN."
  (interactive
   (list (intern
          (completing-read "Toggle visibility of: "
                           '(Mode Ids Ratio Date&Time)
                           nil t))))
  (setq-local archive-hidden-columns
              (if (memq column archive-hidden-columns)
                  (remove column archive-hidden-columns)
                (cons column archive-hidden-columns)))
  (archive-resummarize))

	       (or (and archive-subfile-mode (archive--file-desc-ext-file-name
		                              archive-subfile-mode))
	  ;; FIXME: Use archive-resummarize?
  (or (eq op #'file-exists-p)
(defun archive-goto-file (file)
  "Go to FILE in the current buffer.
FILE should be a relative file name.  If FILE can't be found,
return nil.  Otherwise point is returned."
  (let ((start (point))
        found)
    (goto-char (point-min))
    (while (and (not found)
                (not (eobp)))
      (forward-line 1)
      (when-let ((descr (archive-get-descr t)))
        (when (equal (archive--file-desc-ext-file-name descr) file)
          (setq found t))))
    (if (not found)
        (progn
          (goto-char start)
          nil)
      (point))))

(defun archive-next-file-displayer (file regexp n)
  "Return a closure to display the next file after FILE that matches REGEXP."
  (let ((short (replace-regexp-in-string "\\`.*:" "" file))
        next)
    (archive-goto-file short)
    (while (and (not next)
                ;; Stop if we reach the end/start of the buffer.
                (if (> n 0)
                    (not (eobp))
                  (not (save-excursion
                         (beginning-of-line)
                         (bobp)))))
      (archive-next-line n)
      (when-let ((descr (archive-get-descr t)))
        (let ((candidate (archive--file-desc-ext-file-name descr))
              (buffer (current-buffer)))
          (when (and candidate
                     (string-match-p regexp candidate))
            (setq next (lambda ()
                         (kill-buffer (current-buffer))
                         (switch-to-buffer buffer)
                         (archive-extract)))))))
    (unless next
      ;; If we didn't find a next/prev file, then restore
      ;; point.
      (archive-goto-file short))
    next))

(defun archive-copy-file (file new-name)
  "Copy FILE to a location specified by NEW-NAME.
Interactively, FILE is the file at point, and the function prompts
for NEW-NAME."
  (interactive
   (let ((name (archive--file-desc-ext-file-name (archive-get-descr))))
     (list name
           (read-file-name (format "Copy %s to: " name)))))
  (when (file-directory-p new-name)
    (setq new-name (expand-file-name file new-name)))
  (when (and (file-exists-p new-name)
             (not (yes-or-no-p (format "%s already exists; overwrite? "
                                       new-name))))
    (user-error "Not overwriting %s" new-name))
  (let* ((descr (archive-get-descr))
         (archive (buffer-file-name))
         (extractor (archive-name "extract"))
         (ename (archive--file-desc-ext-file-name descr)))
    (with-temp-buffer
      (archive--extract-file extractor archive ename)
      (write-region (point-min) (point-max) new-name))))

         (ename (archive--file-desc-ext-file-name descr))
         (iname (archive--file-desc-int-file-name descr))
          (setq-local archive-superior-buffer archive-buffer)
	       (null (archive--extract-file extractor archive ename))
(defun archive--extract-file (extractor archive ename)
  (let (;; We may have to encode the file name argument for
	;; external programs.
	(coding-system-for-write
	 (and enable-multibyte-characters
	      archive-file-name-coding-system))
	;; We read an archive member by no-conversion at
	;; first, then decode appropriately by calling
	;; archive-set-buffer-as-visiting-file later.
	(coding-system-for-read 'no-conversion)
	;; Avoid changing dir mtime by lock_file
	(create-lockfiles nil))
    (condition-case err
	(if (fboundp extractor)
	    (funcall extractor archive ename)
	  (archive-*-extract archive ename
			     (symbol-value extractor)))
      (error
       (ding (message "%s" (error-message-string err)))
       nil))))

  (let* ((ename (archive--file-desc-ext-file-name descr))
	  (if (archive--file-desc-mode descr)
	      (set-file-modes tmpfile
	                      (logior ?\400 (archive--file-desc-mode descr))))
  (interactive "sNew mode (octal or symbolic): ")
	    (setq files (cons (archive--file-desc-ext-file-name
	                       (archive-get-descr))
	                      files)))
(defun archive--mode-revert (orig-fun &rest args)
    (let ((coding-system-for-read 'no-conversion))
      (apply orig-fun t t (cddr args)))

(defun archive--fit (str len)
  (let* ((spaces (- len (string-width str)))
         (pre (/ spaces 2)))
    (if (< spaces 1)
        (substring str 0 len)
      (concat (make-string pre ?\s) str (make-string (- spaces pre) ?\s)))))

(defun archive--fit2 (str1 str2 len)
  (let* ((spaces (- len (string-width str1) (string-width str2))))
    (if (< spaces 1)
        (substring (concat str1 str2) 0 len)
      (concat str1 (make-string spaces ?\s) str2))))

(defun archive--enabled-p (column)
  (not (memq column archive-hidden-columns)))

(defun archive--summarize-descs (descs)
  (goto-char (point-min))
  (if (null descs)
      (progn (insert "M  ...   Filename\n")
             (insert "- ----- ---------------\n")
             (archive-summarize-files nil)
             (insert "- ----- ---------------\n"))
    (let* ((sample (car descs))
           (maxsize 0)
           (maxidlen 0)
           (totalsize 0)
           (times (archive--enabled-p 'Date&Time))
           (ids (and (archive--enabled-p 'Ids)
                     (or (archive--file-desc-uid sample)
                         (archive--file-desc-gid sample))))
           ;; For ratio, date/time, and mode, we presume that
           ;; they're either present on all entries or on nonel, and that they
           ;; take the same space on each of them.
           (ratios (and (archive--enabled-p 'Ratio)
                        (archive--file-desc-ratio sample)))
           (ratiolen (if ratios (string-width ratios)))
           (timelen (length (archive--file-desc-time sample)))
           (samplemode (and (archive--enabled-p 'Mode)
                            (archive--file-desc-mode sample)))
           (modelen (length (if samplemode (file-modes-number-to-symbolic samplemode)))))
      (dolist (desc descs)
        (when ids
          (let* ((uid (archive--file-desc-uid desc))
                 (gid (archive--file-desc-uid desc))
                 (len (cond
                       ((not uid) (string-width gid))
                       ((not gid) (string-width uid))
                       (t (+ (string-width uid) (string-width gid) 1)))))
            (if (> len maxidlen) (setq maxidlen len))))
        (let ((size (archive--file-desc-size desc)))
          (cl-incf totalsize size)
          (if (> size maxsize) (setq maxsize size))))
      (let* ((sizelen (length (number-to-string maxsize)))
             (dash
              (concat
               "- "
               (if (> modelen 0) (concat (make-string modelen ?-) "  "))
               (if ids (concat (make-string maxidlen ?-) "  "))
               (make-string sizelen ?-) " "
               (if ratios (concat (make-string (1+ ratiolen) ?-) " "))
               " "
               (if times (concat (make-string timelen ?-) "  "))
               "----------------\n"))
             (startcol (+ 2
                          (if (> modelen 0) (+ 2 modelen) 0)
                          (if ids (+ maxidlen 2) 0)
                          sizelen 2
                          (if ratios (+ 2 ratiolen) 0)
                          (if times (+ timelen 2) 0))))
        (insert
         (concat "M "
                 (if (> modelen 0) (concat (archive--fit "Mode" modelen) "  "))
                 (if ids (concat (archive--fit2 "Uid" "Gid" maxidlen) "  "))
                 (archive--fit "Size" sizelen) " "
                 (if ratios (concat (archive--fit "Cmp" (1+ ratiolen)) " "))
                 " "
                 (if times (concat (archive--fit "Date&time" timelen) "  "))
                 " Filename\n"))
        (insert dash)
        (archive-summarize-files
         (mapcar (lambda (desc)
                   (let* ((size (number-to-string
                                 (archive--file-desc-size desc)))
                          (text
                           (concat "  "
                                   (when (> modelen 0)
                                     (concat (file-modes-number-to-symbolic
                                              (archive--file-desc-mode desc))
                                             "  "))
                                   (when ids
                                     (concat (archive--fit2
                                              (archive--file-desc-uid desc)
                                              (archive--file-desc-gid desc)
                                              maxidlen) "  "))
                                   (make-string (- sizelen (length size)) ?\s)
                                   size
                                   " "
                                   (when ratios
                                     (concat (archive--file-desc-ratio desc)
                                             "% "))
                                   " "
                                   (when times
                                     (concat (archive--file-desc-time desc)
                                             "  "))
                                   (archive--file-desc-int-file-name desc))))
                     (archive--file-summary
                      text startcol (length text))))
                 descs))
        (insert dash)
        (insert (format (format "%%%dd %%s %%d files\n"
                                (+ 2
                                   (if (> modelen 0) (+ 2 modelen) 0)
                                   (if ids (+ maxidlen 2) 0)
                                   sizelen))
                        totalsize
                        (make-string (+ (if times (+ 2 timelen) 0)
                                        (if ratios (+ 2 ratiolen) 0) 1)
                                     ?\s)
                        (length descs))))))
  (apply #'vector descs))

        files)
             (ifnname (if fiddle (downcase efnname) efnname)))
        (setq files (cons (archive--file-desc
                           efnname ifnname nil ucsize
                           (concat (archive-dosdate moddate)
                                   " " (archive-dostime modtime))
                           :pos (1- p))
    (archive--summarize-descs (nreverse files))))
  (let ((name (concat newname (make-string (- 13 (length newname)) ?\0)))
	(goto-char (+ archive-proper-file-start 2
	              (archive--file-desc-pos descr)))
        files)
	     fnlen efnname osid fiddle ifnname p2
	     mode uid gid dir prname
	(if neh ;if level 1 or 2 we expect extension headers to follow
		(cond
		 ((= etype 1)           ;file name
		 ((= etype 2)           ;directory name
		      (setq dir (concat dir
					(if (= (get-byte i)
					       255)
					    "/"
					  (char-to-string
					   (char-after i)))))
		      (setq i (1+ i)))))
		 )
        (push (archive--file-desc
               prname ifnname mode ucsize
               (concat moddate " " modtime)
               :pos (1- p)
               :uid (or uname (if uid (number-to-string uid)))
               :gid (or gname (if gid (number-to-string gid))))
              files)
    (archive--summarize-descs (nreverse files))))
      (let* ((p        (+ archive-proper-file-start
	                  (archive--file-desc-pos descr)))
	(let* ((p (+ archive-proper-file-start (archive--file-desc-pos fil)))
		     (archive--file-desc-int-file-name fil) errtxt)))))))
   (lambda (old) (archive-calc-mode old newmode))
        files)
             ;; (lheader (archive-l-e (+ p 42) 4))
			   (memq creator '(0 2 4 5 9))
             (ifnname (if fiddle (downcase efnname) efnname)))
        (setq files (cons (archive--file-desc
			   efnname ifnname mode ucsize
			   (concat (archive-dosdate moddate)
				   " " (archive-dostime modtime))
			   :pos (1- p))
			  files)
    (archive--summarize-descs (nreverse files))))
(defun archive--file-desc-case-fiddled (fd)
  (not (eq (archive--file-desc-int-file-name fd)
           (archive--file-desc-ext-file-name fd))))

   (if (archive--file-desc-case-fiddled descr)
       archive-zip-update-case archive-zip-update)))
	(let* ((p (+ archive-proper-file-start
	             (archive--file-desc-pos fil)))
	       (oldmode (archive--file-desc-mode fil))
	       (newval  (archive-calc-mode oldmode newmode))
        files)
             (ifnname (if fiddle (downcase efnname) efnname)))
        (setq files (cons (archive--file-desc
                           efnname ifnname nil ucsize
                           (concat (archive-dosdate moddate)
                                   " " (archive-dostime modtime)))
    (archive--summarize-descs (nreverse files))))
      (unwind-protect
          (call-process "lsar" nil t nil "-l" (or file copy))
        (if copy (delete-file copy)))
      (re-search-forward "^\\(?:\s+=+\\)+\s*\n")
                                 "\\([-0-9.]+\\)%?\s+"      ; Ratio
          (push (archive--file-desc name name nil
                                    ;; Size
                                    (string-to-number size)
                                    ;; Date&Time.
                                    (concat (match-string 4) " " (match-string 5))
                                    :ratio (match-string 2))
    (archive--summarize-descs (nreverse files))))
  (let ((file buffer-file-name)
          (push (archive--file-desc name name nil (string-to-number size) time)
    (archive--summarize-descs (nreverse files))))
(defun archive-ar--name (name)
  "Return the external name represented by the entry NAME.
NAME is expected to be the 16-bytes part of an ar record."
  (cond ((equal name "//              ")
         (propertize ".<ExtNamesTable>." 'face 'italic))
        ((equal name "/               ")
         (propertize ".<LookupTable>." 'face 'italic))
        ((string-match "/? *\\'" name)
         ;; FIXME: Decode?  Add support for longer names?
         (substring name 0 (match-beginning 0)))))

  (let* ((files ()))
      (let* ((name (match-string 1))
             extname
             (time (string-to-number (match-string 2)))
             (user (match-string 3))
             (group (match-string 4))
             (mode (string-to-number (match-string 5) 8))
             (sizestr (match-string 6))
             (size (string-to-number sizestr)))
        (setq extname (archive-ar--name name))
        (push (archive--file-desc extname extname mode size time
                                  :uid user :gid group)
    (archive--summarize-descs (nreverse files))))
              (if (equal name (archive-ar--name this))
                (forward-char size)
                (if (eq ?\n (char-after)) (forward-char 1)))))
(defun archive-ar-write-file-member (archive descr)
  (archive-*-write-file-member
   archive
   descr
   '("ar" "r")))

