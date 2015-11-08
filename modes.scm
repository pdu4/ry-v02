(define *modes* '())
(define *current-mode* '())

(define (enter-mode new-mode)
  (set! *current-mode* new-mode))

(define (new-mode name keybinding)
  (set! *modes* (cons
                  (cons name keybinding)
                  *modes*))
  (if (null? *current-mode*)
    (set! *current-mode* name))
  (lambda ()
    (enter-mode name)))

(define (current-mode)
  (assq *current-mode* *modes*))

(define (current-mode-name)
  *current-mode*)

(define (current-mode-keybinding)
  (cdr (current-mode)))

(define (mode-match-keypress keybinding ch)
  (let ([f (assv ch keybinding)])
    (if f (cdr f) #f)))

(define (define-binding alist)
  alist)

(define (numbers-binding fn)
  (list (cons #\0 fn)
    (cons #\1 fn) (cons #\2 fn) (cons #\3 fn)
    (cons #\4 fn) (cons #\5 fn) (cons #\6 fn)
    (cons #\7 fn) (cons #\8 fn) (cons #\9 fn)))

(define (nested-numbers-binding fn)
  (define-binding
    (append
      (numbers-binding fn)
      (numbers-binding
        (define-binding
          (append
            (numbers-binding fn)
            (numbers-binding
              (define-binding
                (numbers-binding fn)))))))))

(define (self-inserting-char-list fn)
  (let loop ([current-char 32]
             [keybindings '()])
    (if (> current-char 126)
      keybindings
      (let* ([ch (integer->char current-char)]
             [values-fn (lambda ()
                          (values
                            (+ current-char 1)
                            (cons (cons ch (fn ch))
                                  keybindings)))])
        (call-with-values values-fn loop)))))

(define normal-mode
  (new-mode
    'normal
    (define-binding
      (list
        (cons #\q save-buffers-kill-ry)
        (cons #\i (lambda () (enter-mode 'insert)))
        (cons #\a (lambda () (forward-char) (enter-mode 'insert)))
        (cons #\A (lambda () (end-of-line) (enter-mode 'insert)))
        (cons #\0 beginning-of-line)
        (cons #\$ end-of-line)
        (cons #\h backward-char)
        (cons #\j next-line)
        (cons #\k previous-line)
        (cons #\l forward-char)
        (cons #\d
          (define-binding
            (list
              (cons #\d kill-whole-line)
              (cons #\h delete-backward-char)
              (cons #\j delete-backward-char)
              (cons #\k delete-forward-char)
              (cons #\l delete-forward-char))))
        (cons #\: smex)
        (cons #\x delete-char)
        (cons #\r (self-inserting-char-list change-char))))))

(define insert-mode
  (new-mode
    'insert
    (define-binding
      (append
        (self-inserting-char-list self-insert-char)
        (list
          (cons #\escape (lambda ()
                          (enter-mode 'normal) (backward-char)))
          (cons #\backspace (lambda () (backward-char) (delete-char)))
          (cons #\delete (lambda () (backward-char) (delete-char)))
          (cons #\space (self-insert-char #\space)))))))

(define command-mode
  (new-mode
    'command
    (define-binding
      (append
        (self-inserting-char-list command-mode-insert-char)
        (list
          (cons #\x0D command-mode-commit)
          (cons #\escape normal-mode)
          (cons #\backspace command-mode-delete-char)
          (cons #\delete command-mode-delete-char)
          (cons #\space (command-mode-insert-char #\space)))))))