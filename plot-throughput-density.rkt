#lang typed/racket

(provide Throughput-Data
         throughput-data?
         throughput-data
         plot-throughput)

(require (only-in "history.rkt"
                  History
                  Entry
                  Entry-delta
                  sum-size
                  Lambda-name
                  App-lambda
                  Result-stat
                  Delta-result
                  Stat-stage-in-lst
                  Stat-stage-out-lst
                  Interval-duration
                  Stat-run
                  Stat
                  App
                  Delta))

(require (only-in plot
                  density
                  log-transform
                  log-ticks
                  plot
                  plot-x-transform
                  plot-x-ticks
                  renderer2d))

(require (only-in "plot-common.rkt"
                  PLOT-WIDTH
                  PLOT-HEIGHT))


(define MAX-THROUGHPUT : Real 0.5) ; maximum throughput in GiBit/s


(define-type Throughput-Data (Listof Real))

(define-predicate throughput-data? Throughput-Data)

(: throughput-data (History -> Throughput-Data))
(define (throughput-data history)

  (for/fold ([data : (Listof Real) '()])
            ([app-delta-pair : Entry history])
    
    (define stat : Stat
      (Result-stat (Delta-result (Entry-delta app-delta-pair))))

    (define input-size : Real
      (sum-size (Stat-stage-in-lst stat)))

    (define duration : Real
      (Interval-duration (Stat-run stat)))

    (define v : Real
      (/ (* input-size 8.0) duration 1024.0 1024.0 1024.0))

    (if (<= v MAX-THROUGHPUT)
        (cons v data)
        data)))

(: plot-throughput (Throughput-Data Path-String -> Void))
(define (plot-throughput tp-data filename)

  (define renderer : renderer2d
    (density tp-data))

      (plot renderer
            #:x-label "Foreign function throughput [GiBit/s]"
            #:y-label "Probability density"
            #:x-min 0
            #:x-max MAX-THROUGHPUT
            #:y-min 0
            #:width PLOT-WIDTH
            #:height PLOT-HEIGHT
            #:legend-anchor 'top-right
            #:out-file filename
            #:out-kind 'png)

  (void))