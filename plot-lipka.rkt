;; cfplot: Cuneiform log visualization tool
;;
;; Copyright 2019 Jörgen Brandt <joergen@cuneiform-lang.org>
;;
;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.
;;
;; -------------------------------------------------------------------

#lang typed/racket/base


;;===============================================================
;; Provisions
;;===============================================================

(provide ; API functions
         lipka-data
         plot-lipka

         ; predicates
         lipka-data?

         ; type defintions
         Lipka-Data)


;;===============================================================
;; Requirements
;;===============================================================

(require (only-in "plot-common.rkt"
                  PLOT-WIDTH
                  PLOT-HEIGHT))

(require (only-in "history.rkt"
                  t-start
                  t-end
                  lambda-name-lst
                  Entry
                  Entry-app
                  Entry-delta
                  Delta-result
                  Result-stat
                  Stat-sched
                  Interval-t-start
                  Interval-duration
                  App-lambda
                  Lambda-name
                  Stat-run
                  History
                  Stat
                  App
                  Delta
                  Lambda
                  Interval
                  Result))

(require (only-in plot
                  lines-interval
                  plot
                  renderer2d))

(require (only-in racket/list
                  range))

(require/typed racket/list
               [index-of ((Listof Any) Any -> (U Nonnegative-Integer False))])

;;===============================================================
;; Type Definitions
;;===============================================================

(define-type Lipka-Data
  (Listof (Pairof String                    ; foreign function name
                  (Listof (Listof Real))))) ; stacked time/count pairs

(define-predicate lipka-data? Lipka-Data)





;;====================================================================
;; Lipka plots
;;====================================================================

(: lipka-data (History -> Lipka-Data))
(define (lipka-data history)

  (define t0 : Real
    (t-start history))

  (define t1 : Real
    (t-end history))

  (define lname-lst : (Listof String)
    (lambda-name-lst history))

  (define step : Real
    (/ (- t1 t0) 2048.0))

  (define t-lst : (Listof Real)
    (range t0 t1 step))

  (define bottom-baseline : (Listof Real)
    (for/list ([t (in-list t-lst)])
      0))

  (define-values (top-baseline alst)
    (for/fold ([baseline    : (Listof Real) bottom-baseline]
               [alst        : (Listof (Pairof String (Listof (Listof Real)))) '()])
              ([lambda-name : String (in-list lname-lst)])

      ; define a predicate deciding if an app/delta pair has the current lambda name
      (: current-lambda? (Entry -> Boolean))
      (define (current-lambda? app-delta-pair)
        (equal? lambda-name
                (Lambda-name (App-lambda (Entry-app app-delta-pair)))))

      (define current-history : History
        (filter current-lambda? history))

      ; filter the history to contain only app/delta pairs of the current lambda name
      (define run-lst : (Listof Interval)
        (for/list ([app-delta-pair : Entry (in-list current-history)])
          (Stat-run (Result-stat (Delta-result (Entry-delta app-delta-pair))))))

      ; for each point in time count the currently running applications
      (define ts : (Listof (Listof Real))
        (for/list ([t : Real (in-list t-lst)]
                   [y : Real (in-list baseline)])

          (define cnt : Real
            (for/fold ([cnt : Real     0])
                      ([run : Interval (in-list run-lst)])

              (define t0 : Real (Interval-t-start run))
              (define t1 : Real (+ t0 (Interval-duration run)))

              (if (and (>= t t0) (< t t1))
                  (add1 cnt)
                  cnt)))

          (list (/ (- t t0) 3600.0) (+ y cnt))))

      (define baseline1 : (Listof Real)
        (for/list ([p : (Listof Real) (in-list ts)])
          (cadr p)))

      (define association : (Pairof String (Listof (Listof Real)))
        (cons lambda-name ts))
      
      (values baseline1 (cons association alst))))


  (define stat-lst : (Listof Stat)
    (for/list ([app-delta-pair : Entry (in-list history)])
      (Result-stat (Delta-result (Entry-delta app-delta-pair)))))


  (define stage-in-ts : (Listof (Listof Real))
    (for/list ([t : Real (in-list t-lst)]
               [y : Real (in-list top-baseline)])

      (define cnt : Real
        (for/fold ([cnt  : Real 0])
                  ([stat : Stat (in-list stat-lst)])

          (define t0 : Real (Interval-t-start (Stat-sched stat)))
          (define t1 : Real (Interval-t-start (Stat-run stat)))

          (if (and (>= t t0) (< t t1))
              (add1 cnt)
              cnt)))
            
      (list (/ (- t t0) 3600.0) (+ y cnt))))

  (define top-top-baseline : (Listof Real)
    (for/list ([p : (Listof Real) (in-list stage-in-ts)])
      (cadr p)))

  (define stage-in-association : (Pairof String (Listof (Listof Real)))
    (cons "stage-in" stage-in-ts))
  
  (define stage-out-ts : (Listof (Listof Real))
    (for/list ([t : Real (in-list t-lst)]
               [y : Real (in-list top-top-baseline)])

      (define cnt : Real
        (for/fold ([cnt  : Real 0])
                  ([stat : Stat (in-list stat-lst)])

          (define t0 : Real
            (+ (Interval-t-start (Stat-run stat))
               (Interval-duration (Stat-run stat))))
          
          (define t1 : Real
            (+ (Interval-t-start (Stat-sched stat))
               (Interval-duration (Stat-sched stat))))

          (if (and (>= t t0) (< t t1))
              (add1 cnt)
              cnt)))

      (list (/ (- t t0) 3600.0) (+ y cnt))))

  (define stage-out-association : (Pairof String (Listof (Listof Real)))
    (cons "stage-out" stage-out-ts))

  (reverse (cons stage-out-association (cons stage-in-association alst))))


(: plot-lipka (Lipka-Data Path-String -> Void))
(define (plot-lipka l-data filename)

  ; extract function names
  (define key-lst : (Listof String)
    (for/list ([pair : (Pairof String (Listof (Listof Real))) l-data])
      (car pair)))

  (define zero-baseline : (Listof (Listof Real))
    (for/list ([t : Real (car (cdr (car l-data)))])
      (list t 0)))
      

  (define-values (_ ilst)
    (for/fold ([baseline : (Listof (Listof Real)) zero-baseline]
               [ilst     : (Listof renderer2d) '()])
              ([pair (in-list l-data)])
      (let* ([lambda-name : String                    (car pair)]
             [v-lst       : (Listof (Listof Real))    (cdr pair)]
             [color : (U Nonnegative-Integer Symbol)
               (if (equal? lambda-name "stage-in")
                   'LightGray
                   (if (equal? lambda-name "stage-out")
                       'DarkGray
                       (assert (index-of key-lst lambda-name))))]
             [i : renderer2d
               (lines-interval baseline
                               v-lst
                               #:label lambda-name
                               #:line1-color color
                               #:line2-color color
                               #:color color)])
        (values v-lst (cons i ilst)))))
             

  (plot ilst
        #:x-label "Time [h]"
        #:y-label "Worker allocation"
        #:width PLOT-WIDTH
        #:height PLOT-HEIGHT
        #:x-min 0
        #:y-min 0
        #:legend-anchor 'top-right
        #:out-file filename
        #:out-kind 'png)

  (void))
  
