#lang racket

(provide HERE
         temp-file-base
         json-file
         occ-file
         app-log
         bin-path
         SEP)

;; Each library function is prefixed by the module it came from.
(require racket/runtime-path)
(define-runtime-path HERE ".")

(define temp-file-base "ARDU")

(define json-file 
  (build-path HERE
              (format "~a.json" temp-file-base)))

(define occ-file 
  (build-path HERE
              (format "~a.occ" temp-file-base)))

(define app-log (build-path HERE 
                            (format "~a.log" temp-file-base)))

(define bin-path
  (build-path HERE "tvm" (format "~a" (system-type)) "bin"))

(define SEP
  (case (system-type)
    [(macosx unix) "/"]
    [else "\\"]))
    
          