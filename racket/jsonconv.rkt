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
      
      (define (I o) o)
      
      (define wire-directions
        (find-wire-direction moduleId (I (get-wires working))))
      
      (define wire-names
        (make-wire-name moduleId (I (get-wires working))))
      
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
                (append parameters (quicksort (I decorated-wire-names) string<?))
                ", ")))
      )))

(define (leading-number str)
  (second (regexp-match "([0-9]+).*" (->string str))))
(define (->num s)
  (if (string? s)
      (string->number s)
      s))

#|
  (define src (get wires src))
  (define tgt (get wires tgt))
  
      (define src-modu (->num (get src moduleId)))
      (define src-posn (->num (leading-number (get src terminal))))
      
      (define tgt-modu (->num (get tgt moduleId)))
      (define tgt-posn (->num (leading-number (get tgt terminal))))
      
      (printf "src ~a tgt ~a src-posn ~a tgt-posn ~a~n"
              src-modu tgt-modu
              src-posn tgt-posn)
      ;; Add this wire to the respective in and out lists for the module.
      
      ;; The source module gets the wire in the src-modu.
      (define ins (hash-ref procs src-modu (λ () (make-hash))))
      (define outs (hash-ref procs src-modu (λ () (make-hash))))
      
      (hash-set! ins 
                 src-modu
                  (cons (list src-posn wires)
                        ;; Return an empty list if it is not there.
                        (hash-ref procs src-modu (λ () '()))))
      
      (hash-set! outs
                 tgt-modu
                 (cons (list tgt-posn wires)
                       ;; Return an empty list if it is not there.
                       (hash-ref procs tgt-modu (λ () '()))))
      

|#

(define node%
  (class object%
    (init-field id name)
    (field (outputs (make-hash))
           (inputs (make-hash))
           (params (make-hash)))
    (define/public (set-id n)
      (set! id n))
    
    (define/public (add-output posn val)
      (hash-set! outputs posn val))
    (define/public (add-input posn val)
      (hash-set! inputs posn val))
    (define/public (add-param posn val)
      (hash-set! params posn val))
    
    (define/public (get-outputs) outputs)
    (define/public (get-inputs) inputs)
    (define/public (get-params) params)
    
    (define/public (return-header)
      (define all-params 
       (merge-hashes (list outputs inputs params)))
      (define lop (hash-map all-params (λ (k v) (list k v))))
     (define sorted (quicksort lop (λ (a b) (< (first a) (first b)))))
     
     (format "~a~a" 
             (smoosh name)
             (list-intersperse (map second sorted) ", ")))
    
    (super-new)
    ))

(define procs (make-hash))
(define (load-skeletons modules)
  ;; For each module, load a skeleton object into
  ;; the procs hash.
  (let ([c 0])
    (for-each (λ (m) 
                (hash-set! procs c (new node% 
                                        (id c)
                                        (name (get m name))))
                (set! c (add1 c)))
              modules)))

(define (load-parameters modules)
  (define c 0)
  (for-each (λ (m)
              (define params (hash-ref m 'value))
              (hash-for-each
               params
               (λ (k v)
                 (define num (->num (leading-number k)))
                 (define proc (hash-ref procs c))
                 (send proc add-param num v)))
              (set! c (add1 c)))
            modules))

(define (make-decorator str)
  (if (regexp-match "out" str)
      "!"
      "?"))

(define (load-wires wires)
  ;; For each wire, load data about source and target
  ;; into the appropriate modules.
  (define (opposite sym)
    (if (equal? sym 'src) 'tgt 'src))
  (for-each (λ (w)
              (define src (hash-ref w 'src))
              (define tgt (hash-ref w 'tgt))
              (define src-modu (->num (hash-ref src 'moduleId)))
              (define tgt-modu (->num (hash-ref tgt 'moduleId)))
              (define src-term (hash-ref src 'terminal))
              (define tgt-term (hash-ref tgt 'terminal))
              
              (define src-posn (->num (leading-number src-term)))
              (define tgt-posn (->num (leading-number tgt-term)))
              ;; Get the source proc
              (define src-proc (hash-ref procs src-modu))
              (define tgt-proc (hash-ref procs tgt-modu))
              
              (define wire-name
                (apply string-append
                       (map ->string (list src-modu tgt-modu) )))
              
              ;(printf "Building wire ~a~n" wire-name)
              
              ;; Load connection info into the list
              ;; use make-decorator to get the ?/! right regardless of 
              ;; which way the user drew the arrow. (Otherwise, src and tgt
              ;; could be wonky, and be backwards from what the processes expect).
              (send tgt-proc add-input tgt-posn (format "wire~a~a"
                                                        wire-name (make-decorator tgt-term)))
              (send src-proc add-output src-posn (format "wire~a~a" 
                                                         wire-name (make-decorator src-term))))
            wires))

(define (merge-hashes loh)
  (define h (make-hash))
  (for-each
   (λ (hprime) (hash-for-each hprime (λ (k v) (hash-set! h k v))))
   loh)
  h)

(define (build-procs2 working)
  (define wires (get working wires))
  (define modules (get working modules))
  
  (load-skeletons modules)
  (load-parameters modules)
  (load-wires wires)
  (hash-map procs (λ (k v) (send v return-header)))
  )

(define (uber<? a b)
  (cond
    [(and (string? a) (string? b))
     (string<? a b)]
    [(and (number? a) (number? b))
     (< a b)]
    [else (string<? (format "~a" a)
                    (format "~a" b))]))

(define (build-wire-names working)
  (define wires (get working wires))
  (map (λ (w)
         (define ls 
           (quicksort (list (get (get w src) moduleId) (get (get w tgt) moduleId)) uber<?))
         (define str 
           (apply string-append (map ->string ls)))
         (format "wire~a" str))
       wires))

(define (build-wire-names2 working)
  (define wires (get working wires))
  (map (λ (w)
         (define ls 
           (list (get (get w src) moduleId) (get (get w tgt) moduleId)))
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
  
  ;(define proc-list (map (build-procs (get-working sjson)) ndx*))
  
  (define proc-headers
    (build-procs2 (get-working sjson)))
  
  (s! (format "#INCLUDE \"ardu-see-ardu-do.module\"~n"))
  (s! (format "PROC main~a ()\n" (current-seconds)))
  (s! (format "  SEQ~n"))
  ;(s! (format "    serial.start(TX0, ~a)~n" (get-data 'baud)))
  
  (s! (format "    CHAN INT ~a:~n" 
              (apply string-append
                     (list-intersperse 
                      (build-wire-names2 (get-working sjson))
                      ", "))))
  (s! "    PAR\n")
  (for-each (λ (str)
              (s! (format "      ~a~n" str)))
            proc-headers)
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
