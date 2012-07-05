#lang racket

;; Server modules
;; Functionality for the server is broken down into modules
;; handling one or more endpoints in the dispatcher.
(require 
 (file "infra.rkt")
 (file "arduino.rkt")
 (file "store.rkt")
 (file "system.rkt"))

;; Each library function is prefixed by the module it came from.
(require racket/runtime-path)
(define-runtime-path here ".")

(require web-server/dispatch)
(define-values (dispatch blog-url)
  (dispatch-rules
   [("run" (string-arg)) show-json]
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
(define (show-json req json)
  (define log-op (open-output-file 
                  (build-path here "my.log") #:exists 'append))
  (fprintf log-op "~a~n" (current-seconds))
  (fprintf log-op "~a~n" json)
  (fprintf log-op "~n~a~n" (request-post-data/raw req))
  (close-output-port log-op)
  (response/xexpr 
   `(p ,(format "~a" (current-seconds)))))

;; (current-directory) is the directory that you start the server
;; from, not the directory where the server's source file is
;; located. The best way to get that is with define-runtime-path

(require web-server/servlet-env)
(serve/servlet dispatch
               #:launch-browser? #f
               #:extra-files-paths (list (build-path here "htdocs"))
               #:servlet-path "/"
               #:servlet-regexp #rx""
               #:log-file "its.log")

