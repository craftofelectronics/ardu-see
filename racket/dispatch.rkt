#lang racket

;; Server modules
;; Functionality for the server is broken down into modules
;; handling one or more endpoints in the dispatcher.
(require 
 (file "arduino.rkt")
 (file "store.rkt")
 (file "system.rkt")
 (file "paths.rkt"))


;; Takes a list of functions, and makes sure that
;; we can do everything along the way, returning the result of
;; the last function. There is almost certainly a more elegant,
;; Schemely way to do this.
(define check-pathway
  (λ funs
    (λ (req)
      (cond
        [(empty? (rest funs))
         ((first funs) req)]
        [else
         (if ((first funs) req)
             ((apply check-pathway (rest funs)) req)
             (response/xexpr
              `(p "No.")))]))))

(require web-server/dispatch)
(define-values (dispatch blog-url)
  (dispatch-rules
   [("run" (string-arg)) log-and-run]
   ;; Handled by arduino.rkt
   [("list") list-arduinos]
   [("reset") (check-pathway arduino? 
                             reset-arduino)]
   ;; Handled by store.rkt
   [("set" (string-arg) (string-arg)) set-data/api]
   [("get" (string-arg)) get-data/api]
   
   ))

;; dispatch-rules patterns cover the entire URL, not just the prefix,
;; so your serve-static only matches "/" not anything with that as a
;; prefix. Also, (next-dispatcher) is the default 'else' rule, so it's
;; not necessary.

(require web-server/http)

(define (log-and-run req http-param)
  (define log-op (open-output-file app-log #:exists 'append))
  (fprintf log-op "~a~n" (current-seconds))
  (fprintf log-op "~n~a~n" (request-post-data/raw req))
  (close-output-port log-op)
  
  (run req (request-post-data/raw req))
  
  (response/xexpr 
   `(p ,(format "~a" (current-seconds)))))

;; (current-directory) is the directory that you start the server
;; from, not the directory where the server's source file is
;; located. The best way to get that is with define-runtime-path

(require web-server/servlet-env)
(serve/servlet dispatch
               #:launch-browser? #f
               #:extra-files-paths (list (build-path HERE "htdocs"))
               #:servlet-path "/"
               #:servlet-regexp #rx""
               #:log-file "its.log")

