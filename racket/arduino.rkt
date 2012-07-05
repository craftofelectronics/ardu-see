#lang racket
(require (file "base.rkt"))
(require web-server/http
         (file "store.rkt")
         )

(provide list-arduinos
         reset-arduino
         arduino?)

(define (arduino? req)
  (get-data KEY:ARDUINO))
 
;; reset-arduino
(define (reset-arduino req)
  (let ([dev (get-data KEY:ARDUINO)])
    
    (response/xexpr
     `(html (body (p ,(format "Reset: ~a" dev)))))
    ))
  

;; list-arduinos
(define (make-set-url dev)
  (define the-device (path->string dev))
  `(li (a ((href ,(format "~a/set/~a/~a" BASE-URL KEY:ARDUINO the-device)))
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