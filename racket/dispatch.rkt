#lang racket/base

;; Each library function is prefixed by the module it came from.
(require racket/runtime-path)
(define-runtime-path here ".")

(require web-server/dispatch)
(define-values (dispatch blog-url)
  (dispatch-rules
   [("json") json]
   [("list") list-arduinos]
   [("set" (string-arg) (string-arg)) set-data]
   [("get" (string-arg)) get-data]
   [("run" (string-arg)) show-json]
   ))

;; dispatch-rules patterns cover the entire URL, not just the prefix,
;; so your serve-static only matches "/" not anything with that as a
;; prefix. Also, (next-dispatcher) is the default 'else' rule, so it's
;; not necessary.

(require web-server/http)
(define (json req)
  (response/xexpr
   `(html (body (p "Dynamically")))))

(define (show-json req json)
  (define log-op (open-output-file 
                  (build-path here "my.log") #:exists 'append))
  (fprintf log-op "~a~n" (current-seconds))
  (fprintf log-op "~a~n" json)
  (fprintf log-op "~n~a~n" (request-post-data/raw req))
  (close-output-port log-op)
  (response/xexpr 
   `(p ,(format "~a" (current-seconds)))))

(define data (make-hash))

(define (set-data req key value)
  (hash-set! data key value)
  (response/xexpr
   `(html
     (body
      (p ,(format "Set ~a to ~a" key value))))))

(define (get-data req key)
  (response/xexpr
   `(html
     (body 
      (p ,(hash-ref data key (λ () "Oops")))))))

(define (list-arduinos req)
  (response/xexpr
   `(html
     (body
      (ul 
       ,@(map (λ (s)
               `(li ,(path->string s)))
             (filter (λ (str)
                       (and (regexp-match "tty" str)
                            (regexp-match "usb" str)))
                     (directory-list "/dev"))))))))
  

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

