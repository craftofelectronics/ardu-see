#lang racket

(provide BASE-URL
         PORT
         KEY:ARDUINO)

(define PORT "8000")
(define BASE-URL (format "http://localhost:~a" PORT))

(define KEY:ARDUINO "arduino")