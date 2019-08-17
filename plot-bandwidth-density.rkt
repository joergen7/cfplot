#lang typed/racket/base

;;===============================================================
;; Provisions
;;===============================================================

(provide ; API functions
         bandwidth-data
         plot-bandwidth

         ; predicates
         bandwidth-data?

         ; type defintions
         Bandwidth-Data)


;;===============================================================
;; Requirements
;;===============================================================

(require (only-in "history.rkt"
                  App
                  Delta
                  Delta-result
                  Entry
                  Entry-delta
                  File-Interval
                  File-Interval-duration
                  File-Interval-size
                  History
                  Result
                  Result-stat
                  Stat
                  Stat-stage-in-lst
                  Stat-stage-out-lst))

(require (only-in "plot-common.rkt"
                  PLOT-WIDTH
                  PLOT-HEIGHT))

(require (only-in plot
                  density
                  plot
                  renderer2d))


;;===============================================================
;; Type Definitions
;;===============================================================

  
(define-type Bandwidth-Data
  (Pairof (Listof Real)   ; input samples in GiBit/s
          (Listof Real))) ; output samples in GiBit/s

(define-predicate bandwidth-data? Bandwidth-Data)


;;====================================================================
;; Bandwidth plots
;;====================================================================

(: bandwidth-data (History -> Bandwidth-Data))
(define (bandwidth-data history)

  (: extract-sample ((Listof File-Interval) -> (Listof Real)))
  (define (extract-sample fi-lst)

    (define raw-sample : (Listof Real)
      (for/list ([fi : File-Interval (in-list fi-lst)])

        (define duration : Positive-Real
          (assert (File-Interval-duration fi) positive?)) ; in seconds

        (define size-gibit : Nonnegative-Real
          (* (File-Interval-size fi) 8.0 9.313225746154785e-10)) ; convert Byte to GiBit

        (/ size-gibit duration)))

    raw-sample)

  (define-values (input-sample output-sample)
    (for/fold ([input-sample : (Listof Real) '()]
               [output-sample : (Listof Real) '()])
              ([entry : Entry (in-list history)])

      (define delta : Delta
        (Entry-delta entry))

      (define result : Result
        (Delta-result delta))

      (define stat : Stat
        (Result-stat result))

      (define stage-in-lst : (Listof File-Interval)
        (Stat-stage-in-lst stat))

      (define stage-out-lst : (Listof File-Interval)
        (Stat-stage-out-lst stat))

      (define delta-input-sample : (Listof Real)
        (extract-sample stage-in-lst))

      (define delta-output-sample : (Listof Real)
        (extract-sample stage-out-lst))
      
      (values (append input-sample delta-input-sample)
              (append output-sample delta-output-sample))))

  
  (cons input-sample output-sample))



(: plot-bandwidth (Bandwidth-Data Path-String -> Void))
(define (plot-bandwidth bw-data filename)

  (define input-sample : (Sequenceof Real)
    (car bw-data))

  (define output-sample : (Sequenceof Real)
    (cdr bw-data))

  (define input-renderer : renderer2d
    (density input-sample
             #:color 'RoyalBlue
             #:label "Stage-in"))

  (define output-renderer : renderer2d
    (density output-sample
             #:color 'Crimson
             #:label "Stage-out"))

  (plot (list input-renderer
              output-renderer)
        #:x-label "Bandwidth [GiBit/s]"
        #:y-label "Probability density"
        #:x-min 0
        #:y-min 0
        #:width PLOT-WIDTH
        #:height PLOT-HEIGHT
        #:legend-anchor 'top-right
        #:out-file filename
        #:out-kind 'png)

  (void))

