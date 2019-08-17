#lang typed/racket/base


(provide Stage-In-Bandwidth-Density-Node-Data
         stage-in-bandwidth-density-node-data
         plot-stage-in-bandwidth-density-node)


(require (only-in plot
                  density
                  plot
                  renderer2d)

         (only-in "history.rkt"
                  History
                  Entry
                  Entry-app
                  Entry-delta
                  App
                  App-lambda
                  Lambda
                  Lambda-name
                  Delta
                  Delta-result
                  Result
                  Result-stat
                  Stat
                  Stat-stage-in-lst
                  Stat-node
                  File-Interval
                  File-Interval-size
                  File-Interval-duration)

         (only-in "pick-color.rkt"
                  pick-color)

         (only-in "plot-common.rkt"
                  PLOT-WIDTH
                  PLOT-HEIGHT)

         (only-in racket/string
                  string-split)

         (only-in racket/list
                  last))


(define-type Stage-In-Bandwidth-Density-Node-Data
  (Listof (Pairof String (Listof Real))))

(: stage-in-bandwidth-density-node-data (History -> Stage-In-Bandwidth-Density-Node-Data))
(define (stage-in-bandwidth-density-node-data h)

  (define t : (Mutable-HashTable String (Listof Real))
    (make-hash))

  (: proc-entry (Entry -> Void))
  (define (proc-entry entry)

    (define delta : Delta
      (Entry-delta entry))

    (define result : Result
      (Delta-result delta))

    (define stat : Stat
      (Result-stat result))

    (define node : String
      (last (string-split (Stat-node stat) "@")))

    (define stage-in-lst : (Listof File-Interval)
      (Stat-stage-in-lst stat))

    (: proc-fi (File-Interval -> Void))
    (define (proc-fi fi)

      (define size-byte : Exact-Nonnegative-Integer
        (File-Interval-size fi))

      (define size-gibit : Nonnegative-Real
        (* size-byte 8.0 9.313225746154785e-10))

      (define duration : Nonnegative-Real
        (File-Interval-duration fi))

      (define bandwidth : Real
        (/ size-gibit duration))

      (define bw-lst : (Listof Real)
        (hash-ref t node (λ () '())))

      (hash-set! t node (cons bandwidth bw-lst)))
                
    (for-each proc-fi stage-in-lst))

  (for-each proc-entry h)

  (hash->list t))

(: plot-stage-in-bandwidth-density-node (Stage-In-Bandwidth-Density-Node-Data Path-String -> Void))
(define (plot-stage-in-bandwidth-density-node bwdn-data filename)

  (define rlst : (Listof renderer2d)
    (for/list ([pair : (Pairof String (Listof Real)) (in-list bwdn-data)])
      
      (define node-name : String
        (car pair))

      (define sample : (Listof Real)
        (cdr pair))

      (density sample
               #:label node-name
               #:color (pick-color node-name))))

  (plot rlst
        #:x-label "Stage-in bandwidth [GiBit/s]"
        #:y-label "Probability density"
        #:x-min 0
        #:y-min 0
        #:width PLOT-WIDTH
        #:height PLOT-HEIGHT
        #:legend-anchor 'top-right
        #:out-kind 'png
        #:out-file filename)

  (void))


