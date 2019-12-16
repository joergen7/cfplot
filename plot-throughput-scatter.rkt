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

(provide plot-throughput-scatter
         Throughput-Scatter-Data
         throughput-scatter-data)

(require (only-in plot
                  renderer2d
                  points
                  plot
                  plot-y-transform
                  plot-y-ticks
                  log-transform
                  log-ticks)

         (only-in "history.rkt"
                  History
                  Entry
                  Entry-app
                  Entry-delta
                  sum-size
                  t-start
                  App
                  App-lambda
                  Delta
                  Delta-result
                  Lambda
                  Lambda-name
                  Result
                  Result-stat
                  Stat
                  Stat-run
                  Stat-stage-in-lst
                  Interval
                  Interval-duration
                  Interval-t-start
                  File-Interval
                  File-Interval-size)

         (only-in "pick-color.rkt"
                  pick-color
                  pick-symbol)


         (only-in "plot-common.rkt"
                  PLOT-WIDTH
                  PLOT-HEIGHT))

(define-type Throughput-Scatter-Data
  (Listof (Pairof String (Listof (Vector Real Real)))))







(: throughput-scatter-data (History -> Throughput-Scatter-Data))
(define (throughput-scatter-data h)

  (define t0 : Real
    (t-start h))

  (define t : (Mutable-HashTable String (Listof (Vector Real Real)))
    (make-hash))

  (: process-pair (Entry -> Void))
  (define (process-pair pair)

    (define app : App
      (Entry-app pair))

    (define lambda : Lambda
      (App-lambda app))

    (define lambda-name : String
      (Lambda-name lambda))

    (define delta : Delta
      (Entry-delta pair))

    (define result : Result
      (Delta-result delta))

    (define stat : Stat
      (Result-stat result))

    (define run : Interval
      (Stat-run stat))

    (define duration-s : Real
      (Interval-duration run))

    (define time : Real
      (/ (- (+ (Interval-t-start run)
               (/ duration-s 2))
            t0)
         3600))

    (define stage-in-lst : (Listof File-Interval)
      (Stat-stage-in-lst stat))

    (define size-byte : Exact-Nonnegative-Integer
      (sum-size stage-in-lst))

    (unless (equal? size-byte 0)

      (define size-bit : Real
        (* size-byte 8.0))

      (define throughput : Real
        (/ size-bit duration-s))

      (define ts : (Listof (Vector Real Real))
        (hash-ref t lambda-name (λ () '())))

      (hash-set! t lambda-name (cons (vector time throughput) ts))))

  (for-each process-pair h)

  (hash->list t))


(: plot-throughput-scatter (Throughput-Scatter-Data String -> Void))
(define (plot-throughput-scatter tps-data filename)

  (define r-lst : (Listof renderer2d)
    (for/list ([pair : (Pairof String (Listof (Vector Real Real))) (in-list tps-data)])

      (define lambda-name : String
        (car pair))

      (define time-series : (Listof (Vector Real Real))
        (cdr pair))

      (points time-series
              #:color (pick-color lambda-name)
              #:sym   (pick-symbol lambda-name)
              #:label lambda-name)))


  (parameterize ([plot-y-transform log-transform]
                 [plot-y-ticks (log-ticks)])

  (plot r-lst
        #:x-label "Time [h]"
        #:y-label "Foreign function throughput [Bit/s]"
        #:x-min 0
        #:legend-anchor 'top-right
        #:width PLOT-WIDTH
        #:height PLOT-HEIGHT
        #:out-file filename
        #:out-kind 'png))

  (void))



















