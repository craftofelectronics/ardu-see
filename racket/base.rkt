#lang racket

(require (file "store.rkt"))
(provide BASE-URL
         PORT
         KEY:ARDUINO
         ->string)


(define PORT "8000")
(define BASE-URL (format "http://localhost:~a" PORT))

(define KEY:ARDUINO "arduino")

(define (->string o)
  (format "~a" o))
