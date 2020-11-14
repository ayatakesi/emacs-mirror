;;; arc-mode.el --- simple editing of archives
;; * dos-fns.el:  (Part of Emacs 19).  You get automatic ^M^J <--> ^J
;;                conversion.
;;			Arc	Lzh	Zip	Zoo	Rar	7z
;;			--------------------------------------------
;; View listing		Intern	Intern	Intern	Intern	Y	Y
;; Extract member	Y	Y	Y	Y	Y	Y
;; Save changed member	Y	Y	Y	Y	N	Y
;; Add new member	N	N	N	N	N	N
;; Delete member	Y	Y	Y	Y	N	Y
;; Rename member	Y	Y	N	N	N	N
;; Chmod		-	Y	Y	-	N	N
;; Chown		-	Y	-	-	N	N
;; Chgrp		-	Y	-	-	N	N
(defgroup archive-arc nil
  "ARC-specific options to archive."
  :group 'archive)

(defgroup archive-lzh nil
  "LZH-specific options to archive."
  :group 'archive)

(defgroup archive-zip nil
  "ZIP-specific options to archive."
  :group 'archive)

(defgroup archive-zoo nil
  "ZOO-specific options to archive."
  :group 'archive)

  :type 'directory
  :group 'archive)
  :type 'regexp
  :group 'archive)
  :type 'hook
  :group 'archive)
                 (const :tag "Show the archive summary" nil))
  :group 'archive)
			(string :format "%v")))
  :group 'archive-arc)
			(string :format "%v")))
  :group 'archive-arc)
			(string :format "%v")))
  :group 'archive-arc)
			(string :format "%v")))
  :group 'archive-lzh)
			(string :format "%v")))
  :group 'archive-lzh)
			(string :format "%v")))
  :group 'archive-lzh)
		       (string :format "%v")))
  :group 'archive-zip)
		       (string :format "%v")))
  :group 'archive-zip)
		       (string :format "%v")))
  :group 'archive-zip)
		       (string :format "%v")))
  :group 'archive-zip)
  :version "27.1"
  :group 'archive-zip)
			(string :format "%v")))
  :group 'archive-zoo)
			(string :format "%v")))
  :group 'archive-zoo)
			(string :format "%v")))
  :group 'archive-zoo)
		       (string :format "%v")))
  :group 'archive-7z)
		       (string :format "%v")))
  :group 'archive-7z)
		       (string :format "%v")))
  :group 'archive-7z)
(defvar archive-file-list-start nil "Position of first contents line.")
(defvar archive-file-list-end nil "Position just after last contents line.")
(defvar archive-proper-file-start nil "Position of real archive's start.")
(defvar archive-local-name nil "Name of local copy of remote archive.")
                  :enable (boundp (archive-name "alternate-display"))
(defvar archive-file-name-indent nil "Column where file names start.")
(defvar archive-remote nil "Non-nil if the archive is outside file system.")
(make-variable-buffer-local 'archive-remote)
(defvar archive-member-coding-system nil "Coding-system of archive member.")
(make-variable-buffer-local 'archive-member-coding-system)
(defvar archive-alternate-display nil
(make-variable-buffer-local 'archive-alternate-display)
(defvar archive-subfile-mode nil "Non-nil in archive member buffers.")
(make-variable-buffer-local 'archive-subfile-mode)
(defvar archive-file-name-coding-system nil)
(make-variable-buffer-local 'archive-file-name-coding-system)
(defvar archive-files nil
  "Vector of file descriptors.
Each descriptor is a vector of the form
 [EXT-FILE-NAME INT-FILE-NAME CASE-FIDDLED MODE ...]")
(make-variable-buffer-local 'archive-files)
    (if (integerp elt)
	(insert (if (< elt 128) elt (decode-char 'eight-bit elt)))
      (insert elt))))
(defun archive-int-to-mode (mode)
  "Turn an integer like 0700 (i.e., 448) into a mode string like -rwx------."
  ;; FIXME: merge with tar-grind-file-mode.
  (string
    (if (zerop (logand  8192 mode))
	(if (zerop (logand 16384 mode)) ?- ?d)
      ?c) ; completeness
    (if (zerop (logand   256 mode)) ?- ?r)
    (if (zerop (logand   128 mode)) ?- ?w)
    (if (zerop (logand    64 mode))
	(if (zerop (logand  2048 mode)) ?- ?S)
      (if (zerop (logand  2048 mode)) ?x ?s))
    (if (zerop (logand    32 mode)) ?- ?r)
    (if (zerop (logand    16 mode)) ?- ?w)
    (if (zerop (logand     8 mode))
	(if (zerop (logand  1024 mode)) ?- ?S)
      (if (zerop (logand  1024 mode)) ?x ?s))
    (if (zerop (logand     4 mode)) ?- ?r)
    (if (zerop (logand     2 mode)) ?- ?w)
    (if (zerop (logand     1 mode)) ?- ?x)))

(defun archive-calc-mode (oldmode newmode &optional error)
OLDMODE will be modified accordingly just like chmod(2) would have done.\n
If optional third argument ERROR is non-nil an error will be signaled if
the mode is invalid.  If ERROR is nil then nil will be returned."
  (cond ((string-match "^0[0-7]*$" newmode)
	 (let ((result 0)
	       (len (length newmode))
	       (i 1))
	   (while (< i len)
	     (setq result (+ (ash result 3) (aref newmode i) (- ?0))
		   i (1+ i)))
	   (logior (logand oldmode 65024) result)))
	((string-match "^\\([agou]+\\)\\([---+=]\\)\\([rwxst]+\\)$" newmode)
	 (let ((who 0)
	       (result oldmode)
	       (op (aref newmode (match-beginning 2)))
	       (bits 0)
	       (i (match-beginning 3)))
	   (while (< i (match-end 3))
	     (let ((rwx (aref newmode i)))
	       (setq bits (logior bits (cond ((= rwx ?r)  292)
					     ((= rwx ?w)  146)
					     ((= rwx ?x)   73)
					     ((= rwx ?s) 3072)
					     ((= rwx ?t)  512)))
		     i (1+ i))))
	   (while (< who (match-end 1))
	     (let* ((whoc (aref newmode who))
		    (whomask (cond ((= whoc ?a) 4095)
				   ((= whoc ?u) 1472)
				   ((= whoc ?g) 2104)
				   ((= whoc ?o)    7))))
	       (if (= op ?=)
		   (setq result (logand result (lognot whomask))))
	       (if (= op ?-)
		   (setq result (logand result (lognot (logand whomask bits))))
		 (setq result (logior result (logand whomask bits)))))
	     (setq who (1+ who)))
	   result))
	(t
	 (if error
	     (error "Invalid mode specification: %s" newmode)))))
                     "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"] (1- month))
	  (if (vectorp item)
		(error "Entry is not a regular member of the archive"))))
      (funcall (or (default-value 'major-mode) 'fundamental-mode))
	(make-local-variable 'archive-subtype)
	(setq archive-subtype type)
	(make-local-variable 'revert-buffer-function)
	(setq revert-buffer-function 'archive-mode-revert)
	(auto-save-mode 0)
	(add-hook 'write-contents-functions 'archive-write-file nil t)
	(make-local-variable 'require-final-newline)
	(setq require-final-newline nil)
	(make-local-variable 'local-enable-local-variables)
	(setq local-enable-local-variables nil)
	(make-local-variable 'file-precious-flag)
	(setq file-precious-flag t)
	(make-local-variable 'archive-read-only)
	(setq archive-read-only
	      (or (not (file-writable-p (buffer-file-name)))
		  (and archive-subfile-mode
		       (string-match file-name-invalid-regexp
				     (aref archive-subfile-mode 0)))))

	;; Should we use a local copy when accessing from outside Emacs?
	(make-local-variable 'archive-local-name)
	(setq major-mode 'archive-mode)
      (make-local-variable 'archive-proper-file-start)
      (make-local-variable 'archive-file-list-start)
      (make-local-variable 'archive-file-list-end)
      (make-local-variable 'archive-file-name-indent)
    (set (make-local-variable 'change-major-mode-hook) 'archive-desummarize)
  (setq archive-file-name-indent (if files (aref (car files) 1) 0))
   (apply
    #'concat
    (mapcar
     (lambda (fil)
       ;; Using `concat' here copies the text also, so we can add
       ;; properties without problems.
       (let ((text (concat (aref fil 0) "\n")))
         (add-text-properties
          (aref fil 1) (aref fil 2)
          '(mouse-face highlight
                       help-echo "mouse-2: extract this file into a buffer")
          text)
         text))
     files)))
	       (or (and archive-subfile-mode (aref archive-subfile-mode 0))
  (or (eq op 'file-exists-p)
         (ename (aref descr 0))
         (iname (aref descr 1))
          (make-local-variable 'archive-superior-buffer)
          (setq archive-superior-buffer archive-buffer)
	       (null
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
  (let* ((ename (aref descr 0))
	  (if (aref descr 3)
	      (set-file-modes tmpfile (logior ?\400 (aref descr 3))))
  (interactive "sNew mode (octal or relative): ")
	    (setq files (cons (aref (archive-get-descr) 0) files)))
(defun archive-mode-revert (&optional _no-auto-save _no-confirm)
    (let ((revert-buffer-function nil)
	  (coding-system-for-read 'no-conversion))
      (revert-buffer t t))
	(totalsize 0)
	(maxlen 8)
        files
	visual)
             (ifnname (if fiddle (downcase efnname) efnname))
             (text    (format "  %8d  %-11s  %-8s  %s"
                              ucsize
                              (archive-dosdate moddate)
                              (archive-dostime modtime)
                              ifnname)))
        (setq maxlen (max maxlen fnlen)
	      totalsize (+ totalsize ucsize)
	      visual (cons (vector text
				   (- (length text) (length ifnname))
				   (length text))
			   visual)
	      files (cons (vector efnname ifnname fiddle nil (1- p))
    (goto-char (point-min))
    (let ((dash (concat "- --------  -----------  --------  "
			(make-string maxlen ?-)
			"\n")))
      (insert "M   Length  Date         Time      File\n"
	      dash)
      (archive-summarize-files (nreverse visual))
      (insert dash
	      (format "  %8d                         %d file%s"
		      totalsize
		      (length files)
		      (if (= 1 (length files)) "" "s"))
	      "\n"))
    (apply #'vector (nreverse files))))
  (let ((name (concat newname (substring "\0\0\0\0\0\0\0\0\0\0\0\0\0"
					 (length newname))))
	(goto-char (+ archive-proper-file-start (aref descr 4) 2))
	(totalsize 0)
	(maxlen 8)
        files
	visual)
	     fnlen efnname osid fiddle ifnname width p2
	     mode modestr uid gid text dir prname
	(if neh		;if level 1 or 2 we expect extension headers to follow
		  (cond
		 ((= etype 1)	;file name
		 ((= etype 2)	;directory name
				    (setq dir (concat dir
						       (if (= (get-byte i)
							      255)
							   "/"
							 (char-to-string
							  (char-after i)))))
				    (setq i (1+ i)))))
		   )
	(setq width (if prname (string-width prname) 0))
	(setq modestr (if mode (archive-int-to-mode mode) "??????????"))
	(setq text    (if archive-alternate-display
			  (format "  %8d  %5S  %5S  %s"
				  ucsize
				  (or uid "?")
				  (or gid "?")
				  ifnname)
			(format "  %10s  %8d  %-11s  %-8s  %s"
				modestr
				ucsize
				moddate
				modtime
				prname)))
        (setq maxlen (max maxlen width)
	      totalsize (+ totalsize ucsize)
	      visual (cons (vector text
				   (- (length text) (length prname))
				   (length text))
			   visual)
	      files (cons (vector prname ifnname fiddle mode (1- p))
                          files))
    (goto-char (point-min))
    (let ((dash (concat (if archive-alternate-display
			    "- --------  -----  -----  "
			  "- ----------  --------  -----------  --------  ")
			(make-string maxlen ?-)
			"\n"))
	  (header (if archive-alternate-display
		       "M   Length    Uid    Gid  File\n"
		    "M   Filemode    Length  Date         Time      File\n"))
	  (sumline (if archive-alternate-display
		       "  %8.0f                %d file%s"
		     "              %8.0f                         %d file%s")))
      (insert header dash)
      (archive-summarize-files (nreverse visual))
      (insert dash
	      (format sumline
		      totalsize
		      (length files)
		      (if (= 1 (length files)) "" "s"))
	      "\n"))
    (apply #'vector (nreverse files))))
      (let* ((p        (+ archive-proper-file-start (aref descr 4)))
	(let* ((p (+ archive-proper-file-start (aref fil 4)))
		     (aref fil 1) errtxt)))))))
   ;; This should work even though newmode will be dynamically accessed.
   (lambda (old) (archive-calc-mode old newmode t))
        (maxlen 8)
	(totalsize 0)
        files
	visual
        emacs-int-has-32bits)
             (lheader (archive-l-e (+ p 42) 4))
	     (modestr (if mode (archive-int-to-mode mode) "??????????"))
			   (not (not (memq creator '(0 2 4 5 9))))
             (ifnname (if fiddle (downcase efnname) efnname))
	     (width (string-width ifnname))
             (text    (format "  %10s  %8d  %-11s  %-8s  %s"
			      modestr
                              ucsize
                              (archive-dosdate moddate)
                              (archive-dostime modtime)
                              ifnname)))
        (setq maxlen (max maxlen width)
	      totalsize (+ totalsize ucsize)
	      visual (cons (vector text
				   (- (length text) (length ifnname))
				   (length text))
			   visual)
	      files (cons (if isdir
			      nil
			    (vector efnname ifnname fiddle mode
				    (list (1- p) lheader)))
                          files)
    (goto-char (point-min))
    (let ((dash (concat "- ----------  --------  -----------  --------  "
			(make-string maxlen ?-)
			"\n")))
      (insert "M Filemode      Length  Date         Time      File\n"
	      dash)
      (archive-summarize-files (nreverse visual))
      (insert dash
	      (format "              %8d                         %d file%s"
		      totalsize
		      (length files)
		      (if (= 1 (length files)) "" "s"))
	      "\n"))
    (apply #'vector (nreverse files))))
   (if (aref descr 2) archive-zip-update-case archive-zip-update)))
	(let* ((p (+ archive-proper-file-start (car (aref fil 4))))
	       (oldmode (aref fil 3))
	       (newval  (archive-calc-mode oldmode newmode t))
        (maxlen 8)
	(totalsize 0)
        files
	visual)
             (ifnname (if fiddle (downcase efnname) efnname))
	     (width (string-width ifnname))
             (text    (format "  %8d  %-11s  %-8s  %s"
                              ucsize
                              (archive-dosdate moddate)
                              (archive-dostime modtime)
                              ifnname)))
        (setq maxlen (max maxlen width)
	      totalsize (+ totalsize ucsize)
	      visual (cons (vector text
				   (- (length text) (length ifnname))
				   (length text))
			   visual)
	      files (cons (vector efnname ifnname fiddle nil (1- p))
    (goto-char (point-min))
    (let ((dash (concat "- --------  -----------  --------  "
			(make-string maxlen ?-)
			"\n")))
      (insert "M   Length  Date         Time      File\n"
	      dash)
      (archive-summarize-files (nreverse visual))
      (insert dash
	      (format "  %8d                         %d file%s"
		      totalsize
		      (length files)
		      (if (= 1 (length files)) "" "s"))
	      "\n"))
    (apply #'vector (nreverse files))))
         (maxname 10)
         (maxsize 5)
      (call-process "lsar" nil t nil "-l" (or file copy))
      (if copy (delete-file copy))
      (re-search-forward "^\\(\s+=+\s*\\)+\n")
                                 "\\([-0-9.%]+\\)\s+"      ; Ratio
          (if (> (length name) maxname) (setq maxname (length name)))
          (if (> (length size) maxsize) (setq maxsize (length size)))
          (push (vector name name nil nil
                        ;; Size, Ratio.
                        size (match-string 2)
                        ;; Date, Time.
                        (match-string 4) (match-string 5))
    (setq files (nreverse files))
    (goto-char (point-min))
    (let* ((format (format " %%s %%s  %%%ds %%5s  %%s" maxsize))
           (sep (format format "----------" "-----" (make-string maxsize ?-)
                        "-----" ""))
           (column (length sep)))
      (insert (format format "   Date   " "Time " "Size" "Ratio" "Filename") "\n")
      (insert sep (make-string maxname ?-) "\n")
      (archive-summarize-files (mapcar (lambda (desc)
                                         (let ((text
                                                (format format
                                                         (aref desc 6)
                                                         (aref desc 7)
                                                         (aref desc 4)
                                                         (aref desc 5)
                                                         (aref desc 1))))
                                           (vector text
                                                   column
                                                   (length text))))
                                       files))
      (insert sep (make-string maxname ?-) "\n")
      (apply #'vector files))))
  (let ((maxname 10)
	(maxsize 5)
	(file buffer-file-name)
          (if (> (length name) maxname) (setq maxname (length name)))
          (if (> (length size) maxsize) (setq maxsize (length size)))
          (push (vector name name nil nil time nil nil size)
    (setq files (nreverse files))
    (goto-char (point-min))
    (let* ((format (format " %%%ds %%s %%s" maxsize))
           (sep (format format (make-string maxsize ?-) "-------------------" ""))
           (column (length sep)))
      (insert (format format "Size " "Date       Time    " " Filename") "\n")
      (insert sep (make-string maxname ?-) "\n")
      (archive-summarize-files (mapcar (lambda (desc)
                                         (let ((text
                                                (format format
							(aref desc 7)
							(aref desc 4)
							(aref desc 1))))
                                           (vector text
                                                   column
                                                   (length text))))
                                       files))
      (insert sep (make-string maxname ?-) "\n")
      (apply #'vector files))))
  (let* ((maxname 10)
         (maxtime 16)
         (maxuser 5)
         (maxgroup 5)
         (maxmode 8)
         (maxsize 5)
         (files ()))
      (let ((name (match-string 1))
            extname
            (time (string-to-number (match-string 2)))
            (user (match-string 3))
            (group (match-string 4))
            (mode (string-to-number (match-string 5) 8))
            (size (string-to-number (match-string 6))))
        (setq extname
              (cond ((equal name "//              ")
                     (propertize ".<ExtNamesTable>." 'face 'italic))
                    ((equal name "/               ")
                     (propertize ".<LookupTable>." 'face 'italic))
                    ((string-match "/? *\\'" name)
                     (substring name 0 (match-beginning 0)))))
        (setq mode (tar-grind-file-mode mode))
        (setq size (number-to-string size))
        (if (> (length name) maxname) (setq maxname (length name)))
        (if (> (length time) maxtime) (setq maxtime (length time)))
        (if (> (length user) maxuser) (setq maxuser (length user)))
        (if (> (length group) maxgroup) (setq maxgroup (length group)))
        (if (> (length mode) maxmode) (setq maxmode (length mode)))
        (if (> (length size) maxsize) (setq maxsize (length size)))
        (push (vector name extname nil mode
                      time user group size)
    (setq files (nreverse files))
    (goto-char (point-min))
    (let* ((format (format "%%%ds %%%ds/%%-%ds  %%%ds %%%ds %%s"
                           maxmode maxuser maxgroup maxsize maxtime))
           (sep (format format (make-string maxmode ?-)
                         (make-string maxuser ?-)
                          (make-string maxgroup ?-)
                           (make-string maxsize ?-)
                           (make-string maxtime ?-) ""))
           (column (length sep)))
      (insert (format format "  Mode  " "User" "Group" " Size "
                      "      Date      " "Filename")
              "\n")
      (insert sep (make-string maxname ?-) "\n")
      (archive-summarize-files (mapcar (lambda (desc)
                                         (let ((text
                                                (format format
                                                         (aref desc 3)
                                                         (aref desc 5)
                                                         (aref desc 6)
                                                         (aref desc 7)
                                                         (aref desc 4)
                                                         (aref desc 1))))
                                           (vector text
                                                   column
                                                   (length text))))
                                       files))
      (insert sep (make-string maxname ?-) "\n")
      (apply #'vector files))))
              (if (equal name this)
                (forward-char size) (if (eq ?\n (char-after)) (forward-char 1)))))