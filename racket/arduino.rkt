#lang racket
(require (file "base.rkt"))
(require web-server/http
         (file "store.rkt")
         (file "paths.rkt")
         )

(provide list-arduinos
         arduino?)

(define (arduino? req)
  (get-data 'arduino-port))
  

;; list-arduinos
(define (make-set-url dev)
  (define the-device (path->string dev))
  `(li (a ((href ,(format "~a/set/~a/~a" BASE-URL 'arduino-port the-device)))
          ,the-device)))

(define (list-arduinos req)
  (define devices
    (filter (λ (str)
              (and (regexp-match "tty" str)
                   (regexp-match "usb" str)))
            (directory-list "/dev")))
  (define list-items
    (map (λ (dev) (make-set-url dev)) devices))
  
  (response/xexpr
   `(html
     (body
      (ul ,@list-items)))))