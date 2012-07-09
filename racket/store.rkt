#lang racket
(require web-server/http)

(provide set-data/api
         get-data/api
         get-data
         set-data!
         get-keys)

(define data (make-hash))

(define (->sym v)
  (string->symbol (format "~a" v)))

(define (set-data/api req key value)
  (hash-set! data (->sym key) value)
  (response/xexpr
   `(html
     (body
      (p ,(format "Set ~a to ~a" key value))))))

(define (get-data/api req key)
  (response/xexpr
   `(html
     (body 
      (p ,(hash-ref data (->sym key) (λ () "Oops")))))))

(define (set-data! key value)
  (hash-set! data key value))

(define (get-data key)
  (hash-ref data key (λ () false)))

(define (get-keys)
  (hash-keys data))