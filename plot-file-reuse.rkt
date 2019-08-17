#lang typed/racket/base

(provide file-reuse-data
         plot-file-reuse
         File-Reuse-Data)

(require (only-in typed/racket
                  exact-round)

         (only-in plot
                  area-histogram
                  plot
                  renderer2d)

         (only-in "history.rkt"
                  Entry
                  Entry-delta
                  History
                  App
                  Delta
                  Delta-result
                  Result
                  Result-stat
                  Stat
                  Stat-stage-in-lst
                  File-Interval
                  File-Interval-filename)

         (only-in "plot-common.rkt"
                  PLOT-WIDTH
                  PLOT-HEIGHT))

(define-type File-Reuse-Data (HashTable Natural Natural))

(: file-reuse-data (History -> File-Reuse-Data))
(define (file-reuse-data history)

  (define h : (HashTable String Natural)
    (make-hash))

  (define freq-hash : (HashTable Natural Natural)
    (make-hash))

  (: extract-fi (File-Interval -> Void))
  (define (extract-fi fi)

    (define filename : String
      (File-Interval-filename fi))

    (define reuse : Natural
      (hash-ref h filename (λ () 0)))

    (hash-set! h filename (add1 reuse)))

  (: extract-pair (Entry -> Void))
  (define (extract-pair pair)

    (define delta : Delta
      (Entry-delta pair))

    (define result : Result
      (Delta-result delta))

    (define stat : Stat
      (Result-stat result))

    (define stage-in-lst : (Listof File-Interval)
      (Stat-stage-in-lst stat))

    (for-each extract-fi stage-in-lst))

  (: invert (String Natural -> Void))
  (define (invert filename n)

    (define freq : Natural
      (hash-ref freq-hash n (λ () 0)))

    (hash-set! freq-hash n (add1 freq)))

  (for-each extract-pair history)

  (hash-for-each h invert)

  freq-hash)

(: plot-file-reuse (File-Reuse-Data Path-String -> Void))
(define (plot-file-reuse data filename)

  (: f (Real -> Real))
  (define (f n)
    (assert (hash-ref data (exact-round n) (λ () 0)) real?))

  (define l : (Listof (Pairof Natural Natural))
    (hash->list data))

  (define key-lst : (Listof Natural)
    (for/list ([p : (Pairof Natural Natural) (in-list l)]) (car p)))

  (define max-n : Natural
    (apply max key-lst))

  (define min-bounds : (Listof Real)
    (build-list (add1 max-n)
                (λ ([x : Natural]) (+ 0.5 x))))

  (define r : renderer2d
    (area-histogram f min-bounds))

  (plot r
        #:x-label "file reuse"
        #:y-label "absolute frequency"
        #:y-max 500
        #:width PLOT-WIDTH
        #:height PLOT-HEIGHT
        #:out-file filename
        #:out-kind 'png)

  (void))







