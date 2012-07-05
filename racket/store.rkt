#lang racket
(require web-server/http)

(provide set-data/api
         get-data/api
         get-data)

(define data (make-hash))

(define (set-data/api req key value)
  (hash-set! data key value)
  (response/xexpr
   `(html
     (body
      (p ,(format "Set ~a to ~a" key value))))))

(define (get-data/api req key)
  (response/xexpr
   `(html
     (body 
      (p ,(hash-ref data key (λ () "Oops")))))))

(define (get-data key)
  (hash-ref data key (λ () false)))
