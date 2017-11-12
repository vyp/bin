(define-module (shell)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 match)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim)
  #:use-module (rnrs sorting)
  #:use-module (srfi srfi-1)
  #:use-module (pipe))

(define-public (bell)
  (system* "echo" "-e" "\a"))

(define-public (close-ports . ports)
  (map close-port ports))

(define-public (delete-files . files)
  (map (lambda (file)
         (when (file-exists? file)
           (delete-file file))) files))

(define (editor)
  ((lambda (e) (if (string-null? e) "nano" e)) (getenv "EDITOR")))

(define-public (edit-files . files)
  (system (string-append (editor) " " (string-join files))))

(define-public (mkdir-p . dirs)
  (map (lambda (dir) (unless (file-exists? dir) (mkdir dir)))
       dirs))

(define-public (enter-dir dir)
  (mkdir-p dir)
  (chdir dir))

(define-public (file-append file text)
  ((lambda (port)
     (display text port)
     (close-port port))
   (open-file file "a")))

(define remove-stat-from-file-system-tree
  (match-lambda
    ((name stat)
     name)
    ((name stat children ...)
     (list name (map remove-stat-from-file-system-tree children)))))

(define-public (fs-tree path)
  (remove-stat-from-file-system-tree (file-system-tree path)))

(define-public (home-path path)
  (string-append (getenv "HOME") "/" path))

(define-public (read-file file)
  ((lambda (ls) (with-input-from-file file
              (lambda () (do ((line (read-line) (read-line)))
                        ((eof-object? line))
                      (set! ls (cons line ls)))
                 (reverse ls)))) '()))

(define-public (read-lines port)
  ((lambda (ls)
     (do ((line (read-line port) (read-line port)))
         ((eof-object? line))
       (set! ls (cons line ls)))
     (reverse ls)) '()))

(define-public (sort-file file)
  ((lambda (file-contents)
     (call-with-output-file file
       (lambda (out) (display (-> (list-sort string<? file-contents)
                             (string-join "\n" 'suffix)) out))))
   (read-file file)))

(define-public (system-output command)
  (let* ((port (open-input-pipe command))
         (output (read-delimited "" port)))
    (close-pipe port)
    (if (eof-object? output)
        ""
        output)))

(define-public (touch-files . files)
  (map (lambda (file) (unless (file-exists? file)
                         ((lambda (port)
                            (display "" port)
                            (close-port port))
                          (open-file file "w"))) files)))
