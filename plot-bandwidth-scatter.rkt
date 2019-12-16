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

(provide bandwidth-scatter-data
         plot-bandwidth-scatter
         Bandwidth-Scatter-Data)

(require (only-in plot
                  points
                  plot
                  renderer2d)

         (only-in "history.rkt"
                  read-history
                  History
                  Entry
                  Entry-delta
                  App
                  Delta
                  Delta-result
                  Result
                  Result-stat
                  Stat
                  Stat-sched
                  Stat-stage-in-lst
                  Stat-stage-out-lst
                  Interval
                  Interval-t-start
                  File-Interval
                  File-Interval-t-start
                  File-Interval-duration
                  File-Interval-size)

         (only-in "plot-common.rkt"
                  PLOT-WIDTH
                  PLOT-HEIGHT))

(struct Bandwidth-Scatter-Data
  ([stage-in  : (Listof (Vector Real Real))]
   [stage-out : (Listof (Vector Real Real))]))


(: bandwidth-scatter-data (History -> Bandwidth-Scatter-Data))
(define (bandwidth-scatter-data history)

  (define t0 : Real
    (for/fold ([t-start         : Real  +inf.f])
              ([app-delta-pair  : Entry (in-list history)])

      (define delta       : Delta    (Entry-delta app-delta-pair))
      (define result      : Result   (Delta-result delta))
      (define stat        : Stat     (Result-stat result))
      (define sched       : Interval (Stat-sched stat))
      (define t-start1    : Real     (Interval-t-start sched))
      (define t-start2    : Real     (if (< t-start1 t-start) t-start1 t-start))

      t-start2))

  (: extract-sample ((Listof File-Interval) -> (Listof (Vector Real Real))))
  (define (extract-sample stage-lst)
    (for/list ([fi : File-Interval stage-lst])

      (define t-start : Real
        (File-Interval-t-start fi))

      (define duration : Nonnegative-Real
        (File-Interval-duration fi))

      (define size-gibit : Nonnegative-Real
        (* (File-Interval-size fi) 8.0 9.313225746154785e-10))
            
      (define time : Real
        (/ (- (+ t-start (/ duration 2)) t0) 3600))

      (define bandwidth : Real
        (/ size-gibit duration))

      (vector time bandwidth)))



  (define stage-in-data : (Listof (Vector Real Real))
    (for/fold ([acc : (Listof (Vector Real Real)) '()])
              ([app-delta-pair : Entry history])

      (define stage-in-lst : (Listof File-Interval)
        (Stat-stage-in-lst (Result-stat (Delta-result (Entry-delta app-delta-pair)))))

      (define to-append : (Listof (Vector Real Real))
        (extract-sample stage-in-lst))
            
      (append acc to-append)))

  (define stage-out-data : (Listof (Vector Real Real))
    (for/fold ([acc : (Listof (Vector Real Real)) '()])
              ([app-delta-pair : Entry history])

      (define stage-out-lst : (Listof File-Interval)
        (Stat-stage-out-lst (Result-stat (Delta-result (Entry-delta app-delta-pair)))))

      (define to-append : (Listof (Vector Real Real))
        (extract-sample stage-out-lst))
            
      (append acc to-append)))

  (Bandwidth-Scatter-Data stage-in-data stage-out-data))


(: plot-bandwidth-scatter (Bandwidth-Scatter-Data Path-String -> Void))
(define (plot-bandwidth-scatter bws-data filename)

  (define stage-in-data : (Listof (Vector Real Real))
    (Bandwidth-Scatter-Data-stage-in bws-data))

  (define stage-out-data : (Listof (Vector Real Real))
    (Bandwidth-Scatter-Data-stage-out bws-data))

  (define stage-in-renderer : renderer2d
    (points stage-in-data
            #:color 'RoyalBlue
            #:sym   'plus
            #:label "Stage-in"))

  (define stage-out-renderer : renderer2d
    (points stage-out-data
            #:color 'Crimson
            #:sym   'circle
            #:label "Stage-out"))

  (plot (list stage-in-renderer
              stage-out-renderer)
        #:x-label "Time [h]"
        #:y-label "Bandwidth [GiBit/s]"
        #:x-min 0
        #:y-min 0
        #:width PLOT-WIDTH
        #:height PLOT-HEIGHT
        #:out-file filename
        #:out-kind 'png)

  (void))







