#lang typed/racket/base

;;===============================================================
;; Provisions
;;===============================================================

(provide ; API functions
         selectivity-data
         plot-selectivity

         ; predicates
         selectivity-data?

         ; type defintions
         Selectivity-Data)


;;===============================================================
;; Requirements
;;===============================================================

(require (only-in "history.rkt"
                  Entry
                  Entry-app
                  Entry-delta
                  sum-size
                  File-Interval-size
                  Lambda-name
                  App-lambda
                  Result-stat
                  Delta-result
                  Stat-stage-in-lst
                  Stat-stage-out-lst
                  History
                  App
                  Delta
                  File-Interval
                  Stat)

         (only-in "plot-common.rkt"
                  PLOT-WIDTH
                  PLOT-HEIGHT)

         (only-in "pick-color.rkt"
                  pick-color
                  pick-symbol)

         (only-in plot
                  function
                  log-ticks
                  log-transform
                  plot
                  plot-x-ticks
                  plot-x-transform
                  plot-y-ticks
                  plot-y-transform
                  points
                  renderer2d)

         (only-in typed/racket/draw
                  Color%))


(require/typed racket/list
               [index-of ((Listof Any) Any -> (U Nonnegative-Integer False))])



;;===============================================================
;; Type definitions
;;===============================================================

(define-type Selectivity-Data
  (Listof (Pairof String                    ; foreign function name
                  (Listof (Listof Real))))) ; selectivity samples, i.e., pairs of Byte/Byte

(define-predicate selectivity-data? Selectivity-Data)



;;====================================================================
;; Selectivity plots
;;====================================================================

(: selectivity-data (History -> Selectivity-Data))
(define (selectivity-data history)
  
  (define alst : (HashTable String (Listof (Listof Real)))
    (make-hash))

  (: proc (Entry -> Void))
  (define (proc app-delta-pair)

    (define lambda-name : String
      (Lambda-name (App-lambda (Entry-app app-delta-pair))))
  
    (define stat : Stat
      (Result-stat (Delta-result (Entry-delta app-delta-pair))))

    (define stage-in-size : Real
      (sum-size (Stat-stage-in-lst stat)))

    (define stage-out-size : Real
      (sum-size (Stat-stage-out-lst stat)))
    
    (define sel-point : (Listof Real)
      (list stage-in-size
            stage-out-size))

    (define sel-sample : (Listof (Listof Real))
      (hash-ref alst lambda-name (λ () '())))

    (unless (or (zero? stage-in-size)
                (zero? stage-out-size))
      (hash-set! alst lambda-name (cons sel-point sel-sample))))

  (for-each proc history)

  (hash->list alst))

  
(: plot-selectivity (Selectivity-Data Path-String -> Void))
(define (plot-selectivity pair-lst filename)

  ; extract function names
  (define key-lst : (Listof String)
    (for/list ([pair : (Pairof String (Listof (Listof Real))) pair-lst])
      (car pair)))
              

  ; append all pairs to a single large 2-vector-list
  (define v-lst : (Listof (Listof Real))
    (apply append (ann (for/list ([pair (in-list pair-lst)]) (cdr pair))
                       (Listof (Listof (Listof Real))))))

  (define x-min : Real
    (apply min (ann (for/list ([v (in-list v-lst)]) (car v)) (Listof Real))))

  (define y-min : Real
    (apply min (ann (for/list ([v (in-list v-lst)]) (cadr v)) (Listof Real))))

  (define x-max : Real
    (apply max (ann (for/list ([v (in-list v-lst)]) (car v)) (Listof Real))))

  (define y-max : Real
    (apply max (ann (for/list ([v (in-list v-lst)]) (cadr v)) (Listof Real))))

  (define points-lst : (Listof renderer2d)
    (for/list ([pair (in-list pair-lst)])
      (let* ([lambda-name : String                 (car pair)]
             [v-lst       : (Listof (Listof Real)) (cdr pair)]
             [color       : (Instance Color%)      (pick-color lambda-name)]
             [sym         : Char                   (pick-symbol lambda-name)])
        (points v-lst
                #:label lambda-name
                #:color color
                #:sym   sym))))


  (parameterize ([plot-x-transform log-transform]
                 [plot-y-transform log-transform]
                 [plot-x-ticks (log-ticks)]
                 [plot-y-ticks (log-ticks)])
    
    (plot (cons (function (λ (x) x) #:style 'dot) points-lst)
          #:x-label "Input size [Byte]"
          #:y-label "Output size [Byte]"
          #:x-min (max 1 (/ x-min 3))
          #:x-max (* x-max 3)
          #:y-min (max 1 (/ y-min 3))
          #:y-max (* y-max 3)
          #:width PLOT-WIDTH
          #:height PLOT-HEIGHT
          #:legend-anchor 'top-left
          #:out-file filename
          #:out-kind 'png))

  (void))


