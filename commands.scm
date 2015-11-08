(define (kill-ry)
  (set-running-state #f))

(define q kill-ry)

; TODO Actually save
(define (save-buffers-kill-ry)
  (kill-ry))

; Callback getting command entered.
; Evals given text and pretty prints result to minibuffer
(define (smex-commit command-text)
  (if command-text
    (let* ([corrected-command-text ; automatically appen ) to commands if needed
              (if (eq? #\) (string-ref command-text (- (string-length command-text) 1)))
                command-text
                (string-append command-text ")"))]
            [eval-result (eval-string corrected-command-text)])
      (if (car eval-result)
        (set-minibuffer-message (cdr eval-result))
        (set-minibuffer-error (cdr eval-result))))))

; `smex` reading input from the minibuffer and evals it
; It's similar to ":" in vim or M-x in emacs
(define (smex)
  (edit-minibuffer "(" smex-commit))

; Splits a list in two at a define `elt` index
(define (split-elt l elt)
  (let loop ((head '())
             (tail l)
             (i 0))
   (if (eq? tail '())
     (values l '())
     (if (= elt i)
       (values (reverse head) tail)
       (loop (cons (car tail) head)
             (cdr tail)
             (+ i 1))))))

(define (insert-string% lines pos str)
  (call-with-values
    (lambda () (split-elt lines (cdr pos)))
    (lambda (head rest)
      (if (null? rest) (set! rest '("")))
      (call-with-values
        (lambda () (split-elt (string->list (car rest)) (car pos)))
        (lambda (lhead lrest) (append head (cons (list->string (append lhead (string->list str) lrest)) (cdr rest))))))))

(define (insert-char% lines pos new-char)
  (call-with-values
    (lambda () (split-elt lines (cdr pos)))
    (lambda (head rest)
      (if (null? rest) (set! rest '("")))
      (call-with-values
        (lambda () (split-elt (string->list (car rest)) (car pos)))
        (lambda (lhead lrest) (append head (cons (list->string (append lhead (cons new-char lrest))) (cdr rest))))))))

(define (change-char% lines pos new-char)
  (call-with-values
    (lambda () (split-elt lines (cdr pos)))
    (lambda (head rest)
      (if (null? rest) (set! rest '("")))
      (call-with-values
        (lambda () (split-elt (string->list (car rest)) (car pos)))
        (lambda (lhead lrest) (append head (cons (list->string (append lhead (cons new-char (cdr lrest)))) (cdr rest))))))))

(define (delete-line% lines line)
  (if (< line (length lines))
    (call-with-values
      (lambda () (split-elt lines line))
      (lambda (head rest) (append head (cdr rest))))
    lines))

(define (delete-char% lines pos)
  (if (and (< (cdr pos) (length lines)) (>= (cdr pos) 0))
    (if (and (< (car pos) (string-length (list-ref lines (cdr pos)))) (>= (car pos) 0))
      (call-with-values
        (lambda () (split-elt lines (cdr pos)))
        (lambda (head rest)
          (call-with-values
            (lambda () (split-elt (string->list (car rest)) (car pos)))
            (lambda (lhead lrest) (append head (cons (list->string (append lhead (cdr lrest))) (cdr rest)))))))
        lines)
      lines))

(define (self-insert-char ch)
  (lambda ()
    (update-current-buffer-prop 'lines (lambda (buffer)
      (insert-char% (buffer-lines buffer) (buffer-pointer buffer) ch)))
    (forward-char)))

(define (change-char ch)
  (lambda ()
    (update-current-buffer-prop 'lines (lambda (buffer)
      (change-char% (buffer-lines buffer) (buffer-pointer buffer) ch)))))

(define (kill-whole-line)
  (update-current-buffer-prop 'lines (lambda (buffer)
    (delete-line% (buffer-lines buffer) (cdr (buffer-pointer buffer)))))
  (update-current-buffer-pointer (lambda (buffer)
    (buffer-pointer buffer))))

(define (delete-char)
  (update-current-buffer-prop 'lines (lambda (buffer)
    (delete-char% (buffer-lines buffer) (buffer-pointer buffer)))))

(define (delete-backward-char)
  (backward-char)
  (delete-char))

(define delete-forward-char delete-char)
