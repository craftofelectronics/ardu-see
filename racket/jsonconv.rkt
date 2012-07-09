#lang racket
;; (require (planet dherman/json:4:0))
(require (planet neil/json-parsing:2:0))
(require mzlib/list 
         (prefix-in srfi1: srfi/1))
(require racket/cmdline)
(require (file "base.rkt")
         (file "store.rkt"))
(provide json->occ)

(define VERSION 1.00)

#|
{ name: 'jadudm',
     project: 'testout',
     working: { modules: [Object], wires: [Object], properties: [Object] } }
|#

(define p1 
  "{\"diagram\":{\"name\":\"\",\"project\":\"\",\"working\":{\"modules\":[{\"name\":\"Read Sensor\",\"value\":{\"1int\":\"A0\"},\"config\":{\"position\":[176,34]}},{\"name\":\"Turn On In Range\",\"value\":{\"1int\":\"2\",\"2int\":\"0\",\"3int\":\"100\"},\"config\":{\"position\":[222,214]}}],\"wires\":[{\"src\":{\"moduleId\":0,\"terminal\":\"0out\"},\"tgt\":{\"moduleId\":1,\"terminal\":\"0in\"}}],\"properties\":{\"name\":\"\",\"project\":\"\",\"description\":\"\"}}},\"username\":\"\",\"project\":\"\",\"storage_key\":\"_\"}" )

(define-syntax (get stx)
  (syntax-case stx ()
    [(_ json field)
     #`(hash-ref json (quote field))]))

(define (get-working json)
  (get (get json diagram) working))

(define (get-modules json)
  (get json modules))

(define (get-wires json)
  (get json wires))

(define (get-name module)
  (get module name))

(define smoosh
  (λ (str)
    (regexp-replace* " " str "")))

(define (find-module-index modules name ndx)
  (cond
    [(empty? modules) (error (format "Could not find name: ~a" name))]
    [(equal? name (get-name (first modules)))
     ndx]
    [else
     (find-module-index (rest modules) name (add1 ndx))]))

(define (ns-equal? n-or-s1 n-or-s2)
  (equal? (format "~a" n-or-s1)
          (format "~a" n-or-s2)))
     
(define (find-wire-direction module-index wires)
  (cond
    [(empty? wires) '()]
    
    [(ns-equal? (number->string module-index)
             (get (get (first wires) src) moduleId)) 
     (define term (get (get (first wires) src) terminal))
     (define m
       (regexp-match "[0-9]+(.*)" term))
     (cons (second m)
           (find-wire-direction module-index (rest wires)))]
    
    [(ns-equal? (number->string module-index)
             (get (get (first wires) tgt) moduleId)) 
     (define term (get (get (first wires) tgt) terminal))
     (define m
       (regexp-match "[0-9]+(.*)" term))
     (cons (second m)
           (find-wire-direction module-index (rest wires)))
     ]
    [else
     (find-wire-direction module-index (rest wires))]))

(define (make-wire-name moduleId wires)
  (cond
    [(empty? wires) '()]
    [(or (ns-equal? (number->string moduleId)
                 (get (get (first wires) src) moduleId))
         (ns-equal? (number->string moduleId)
             (get (get (first wires) tgt) moduleId)))
     (define num
       (apply string-append
              (map ->string
                   (quicksort (list (get (get (first wires) src) moduleId)
                                    (get (get (first wires) tgt) moduleId))
                              uber<?))))
     (cons (format "wire~a" num)
           (make-wire-name moduleId (rest wires)))]
    [else
     (make-wire-name moduleId (rest wires))]))
     
(define (symbol<? a b)
  (string<? (symbol->string a)
            (symbol->string b)))

(define (list-intersperse ls o)
    (cond
      [(empty? (rest ls)) ls]
      [else
       (cons (first ls)
             (cons o
                   (list-intersperse (rest ls) o)))]))

(define (snoc ls o)
  (reverse (cons o (reverse ls))))

(define build-procs 
  (λ (working)
    (λ (moduleId)
      ;(define moduleId 
      ;(find-module-index (get-modules working) name 0))
      
      (define me
        (list-ref (get-modules working) moduleId))
 
      (define wire-directions
        (find-wire-direction moduleId (get-wires working)))
      
      (define wire-names
        (make-wire-name moduleId (get-wires working)))
      
      (define decorated-wire-names
        (map (λ (wire-direction wire-name)
               (if (equal? wire-direction "out")
                   (format "~a!" wire-name)
                   (format "~a?" wire-name)))
             wire-directions wire-names))
      
      (define parameters
        (let* ([my-values (get me value)]
               [param-positions (quicksort (hash-keys my-values) symbol<?)])
          (map (λ (key)
                 (hash-ref my-values key))
               param-positions)))
      
      (define name 
        (get (list-ref (get-modules working) moduleId) name))
      
      (format "~a(~a)"
              (smoosh name)
              (apply 
               string-append
               (list-intersperse 
                (append parameters decorated-wire-names)
                ", ")))
      )))
       
(define (uber<? a b)
  (cond
    [(and (string? a) (string? b))
     (string<? a b)]
    [(and (number? a) (number? b))
     (< a b)]
    [else (error (format "uber<?: Cannot compare '~a' with '~a'." a b))]))

(define (build-wire-names working)
  (define wires (get working wires))
  (map (λ (w)
         (define ls 
           (quicksort (list (get (get w src) moduleId) (get (get w tgt) moduleId)) uber<?))
         (define str 
           (apply string-append (map ->string ls)))
         (format "wire~a" str))
       wires))
    
  

(define (json->occ prog)
  (define result "")
  (define (s! s)
    (set! result (string-append result s)))
  
  (define sjson      (json->sjson prog))
  (define names      (map get-name (get-modules (get-working sjson))))
  ;(printf "NAMES: ~a~n" names)
  
  (define proc-names (map smoosh names))
  ;(printf "PROC-NAMES: ~a~n" proc-names)
  
  (define ndx* (srfi1:iota (length names)))
  ;(printf "NDX*: ~a~n" ndx*)
  
  (define proc-list (map (build-procs (get-working sjson)) ndx*))
  
  (s! (format "#INCLUDE \"ardu-see-ardu-do.module\"~n"))
  (s! (format "PROC main~a ()\n" (current-seconds)))
  (s! (format "  SEQ~n"))
  ;(s! (format "    serial.start(TX0, ~a)~n" (get-data 'baud)))
  
  (s! (format "    CHAN INT ~a:~n" 
              (apply string-append
                     (list-intersperse 
                      (build-wire-names (get-working sjson))
                      ", "))))
  (s! "    PAR\n")
  (for-each (λ (str)
              (s! (format "      ~a~n" str)))
            proc-list)
  (s! ":\n")
  result
  )

(define (file->string fname)
  (define ip (open-input-file fname))
  (define s "")
  (let loop ([line (read-line ip)])
    (unless (eof-object? line)
      (set! s (string-append line s))
      (loop (read-line ip))))
  (close-input-port ip)
  s)

(define outfile (make-parameter "ardusee.occ"))

(define (run v)
  (define outfile "ARDU.occ")
  (command-line 
   #:program "jsonconv" 
   #:argv v
   #:once-each
   [("-v" "--version") "Current version"
                       (printf "Version: ~a~n" VERSION)
                       (exit)]
   [("-o" "--outfile") of 
                       "Output filename"
                       (outfile of)]
                       
   #:args (filename)
   (let ([res (json->occ (file->string filename))])
     (define op (open-output-file outfile #:exists 'replace))
     (fprintf op res)
     (close-output-port op))
   ))

;(run (current-command-line-arguments))