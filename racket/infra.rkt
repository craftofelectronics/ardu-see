#lang racket

(provide check-pathway)

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
             ((apply check (rest funs)) req)
             (response/xexpr
              `(p "No.")))]))))