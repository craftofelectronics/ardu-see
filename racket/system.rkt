#lang racket
(require racket/system
         (file "base.rkt")
         (file "paths.rkt")
         (file "jsonconv.rkt")
         (file "store.rkt"))


(require web-server/http)


(provide run set-platform-parameters)

;; FIXME
;; This should all be read from a conf file.
(define (set-platform-parameters req platform)
  (case (string->symbol platform)
    [(uno arduinouno)
     (set-data! 'platform 'uno)
     (set-data! 'baud 115200)
     (set-data! 'mcpu 'm328p)
     ]
    [else ; arduino
     (set-data! 'platform 'arduino)
     (set-data! 'baud 57600)
     (set-data! 'mcpu 'm328p)]
    )
  (response/xexpr 
   `(p ,(format "Set parameters at time ~a" (current-seconds))))
  )

;; RUNNING COMMANDS
;; We'll define commands as S-expressions. The language
;; looks like
;; (cmd -flag0 (-flag1 value1) (= -p1 value2))
;; which becomes
;; "cmd -flag0 -flag1 value1 -p1=value2"
;; Note we don't insert hyphens, but we make sure
;; spaces come out right.

(struct cmd (app args) #:transparent)
(struct arg2 (flag value) #:transparent)
(struct arg1 (flag) #:transparent)
(struct set (param value) #:transparent)

(define (parse sexp)
  (match sexp
    [`(= ,rand1 ,rand2)
     (set rand1 rand2)]
    [`(,command ,args ...)
     (cmd command (map parse args))]
    ;; FIXME: The list of length two is subsumed by
    ;; the previous rule... unnecessary?
    [`(,flag ,value)
     (arg2 flag value)]
    [flag/value
     (arg1 flag/value)]))

(define (list-intersperse ls o)
  (cond
    [(empty? (rest ls)) ls]
    [else
     (cons (first ls)
           (cons o 
                 (list-intersperse (rest ls) o)))]))

(define (render ast)
  (match ast
    [(struct cmd (command args))
     (format "~a ~a" 
             command
             (apply string-append
                    (list-intersperse (map render args) " ")))]
    [(struct set (param value))
     (format "~a=~a" param value)]
    [(struct arg2 (flag value))
     (format "~a ~a" flag value)]
    [(struct arg1 (flag/value))
     (format "~a" flag/value)]))



(define (show-json req json)
  (define log-op (open-output-file 
                  (build-path HERE "my.log") #:exists 'append))
  (fprintf log-op "~a~n" (current-seconds))
  (fprintf log-op "~a~n" json)
  (fprintf log-op "~n~a~n" (request-post-data/raw req))
  (close-output-port log-op)
  (response/xexpr 
   `(p ,(format "~a" (current-seconds)))))

(define (isearch-list)
  (append
   (list HERE)
   (map (λ (p)
          (build-path HERE p))
        (list 
         (build-path "tvm" "common" "lib")
         (build-path "tvm" "common" "include")
         (build-path "tvm" "common" "include" "arch" "m328p")
         (build-path "tvm" "common" "include" "arch" "common")
         (build-path "tvm" "common" "include" "platforms" "arduino")))))

(define (read-cmd baud serial-port)
  (render
   (parse
     `(read_arduino (-b ,baud) ,serial-port))))

(define (compile-cmd fname)
  (format "~a~a~a"
          bin-path
          SEP
          (render
           (parse
             `(occ21 
               -t2 -V -etc -w -y -znd -znec 
               -udo -zncc -init -xin -mobiles 
               -zrpe -zcxdiv -zcxrem -zep -b -tle 
               -DEF (= F.CPU 16000000) 
               -DEF OCCBUILD.TVM ,fname)))))

(define (json->occ-cmd fname)
  (format "~a~a~a"
          bin-path
          SEP
          (render
           (parse 
             `(jsonconv ,fname)))))


(define (save-json-file json)
  (define op (open-output-file json-file #:exists 'replace))
  (fprintf op json)
  (newline op)
  (close-output-port op)
  json-file)

(define (transform-json-file)
  (define op (open-output-file occ-file #:exists 'replace))
  (fprintf op "~a~n" (json->occ (file->string json-file)))
  (close-output-port op))

(define (exe cmd)
  (let-values ([(from-stdout
                 to-stdin
                 process-id
                 from-stderr
                 status-fun) (apply values (process cmd))])
    (let loop ([status (status-fun 'status)])
      (cond
        [(or (equal? status 'done-ok)
             (equal? status 'done-error))
         (close-input-port from-stdout)
         (close-input-port from-stderr)
         (close-output-port to-stdin)]
        [else (loop (status-fun 'status))])
      )))

(define (compile-occam-file)
  (define isearch (apply string-append 
                         (list-intersperse 
                          (map ->string (isearch-list))
                          ":")))
  (define cmd (compile-cmd occ-file))
  
  (set! cmd (format "export ISEARCH=~a ; ~a" isearch cmd))
  (set! cmd (format "cd ~a ; ~a"
                    HERE
                    cmd))
  (printf "COMPILE:~n~a~n" cmd)
  (exe cmd))

(define (plinker-cmd)
  (format "~a~a~a"
          bin-path
          SEP
          (render
           (parse 
             `(plinker.pl -s 
                          -o ,tbc-file
                          ,(->string 
                            (build-path 
                             HERE  "tvm" "common" "lib" "forall.lib"))
                          ,tce-file)))))


(define (plink)
  (exe (plinker-cmd)))

(define (bin2hex-cmd)
  (format "~a~a~a"
          bin-path
          SEP
          (render
           (parse 
             `(binary-to-ihex 0x4F00 ,tbc-file ,hex-file)))))

(define (bin2hex)
  (exe (bin2hex-cmd)))

(define-syntax (when-file stx)
  (syntax-case stx ()
    [(when-file file body ...)
     #`(when (file-exists? file)
         body ...)]))

(define (cleanup-temp-files)
  (for-each (λ (f)
              (when-file f (delete-file f)))
            (list json-file
                  occ-file
                  tce-file
                  tbc-file
                  hex-file)))

(define (build-port sp)
  (define PORT
    (case (system-type)
      [(macosx unix) (format "/dev/~a" sp)]
      [(windows) "FIXME"]))
  PORT)

(define (reset-cmd serial-port)
  (render
   (parse
     `(reset-arduino ,(build-port serial-port) ,(get-data 'baud)))))

(define (reset-arduino)
  (define ARDUINO-PORT (get-data 'arduino-port))
  (define cmd (format "~a~a~a" 
                 bin-path
                 SEP
                 (reset-cmd ARDUINO-PORT)))
  (printf "RESET: ~a~n" cmd)
  (when ARDUINO-PORT
    (exe cmd)))

(define (avrdude-cmd sp)
  (format "~a~a~a"
                     bin-path
                     SEP
                     (render
                      (parse 
                        `(avrdude -C ,(->string conf-file)
                                  -V -F 
                                  (-p ,(get-data 'mcpu)) ;FIXME
                                  (-b ,(get-data 'baud))
                                  (-c arduino)
                                  (-P ,(build-port sp))
                                  -D -U 
                                  ,(format "flash:w:~a" hex-file))))))

(define (avrdude)
  (define ARDUINO-PORT (get-data 'arduino-port))
  (define cmd (avrdude-cmd ARDUINO-PORT))
  (printf "AVRDUDE~n\tport[~a]~n\tcmd: ~a~n" ARDUINO-PORT cmd)
  (when ARDUINO-PORT
    (exe cmd)))

(define (show-table)
  (for-each (λ (k)
         (printf "~a : ~a~n" k (get-data k)))
    (get-keys)))

(define (run req json)
  (show-table)
  (cleanup-temp-files)
  (save-json-file (format "~a" json))
  (transform-json-file)
  (when-file occ-file
    (compile-occam-file))
  (when-file tce-file
    (plink))
  (when-file tbc-file
    (bin2hex))
  
  (when-file hex-file
    (printf "Uploading~n")
    (avrdude))
  )


