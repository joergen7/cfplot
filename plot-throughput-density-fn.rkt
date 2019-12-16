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

(provide Throughput-Density-Fn-Data
         throughput-density-fn-data
         plot-throughput-density-fn)

(require (only-in plot
                  density
                  plot
                  renderer2d)

         (only-in "history.rkt"
                  sum-size
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
                  Result-node
                  Result-stat
                  Stat
                  Stat-stage-in-lst
                  Stat-run
                  Interval
                  Interval-duration
                  File-Interval)

         (only-in "pick-color.rkt"
                  pick-color)

         (only-in "plot-common.rkt"
                  PLOT-WIDTH
                  PLOT-HEIGHT)

         (only-in racket/string
                  string-split)

         (only-in racket/list
                  last))

(define MAX-THROUGHPUT : Real 0.5) ; maximum throughput in GiBit/s


(define-type Throughput-Density-Fn-Data
  (Listof (Pairof String (Listof Real))))

(: throughput-density-fn-data (History -> Throughput-Density-Fn-Data))
(define (throughput-density-fn-data h)

  (define t : (Mutable-HashTable String (Listof Real))
    (make-hash))

  (: proc-entry (Entry -> Void))
  (define (proc-entry entry)

    (define app : App
      (Entry-app entry))

    (define lambda : Lambda
      (App-lambda app))

    (define fn-name : String
      (Lambda-name lambda))

    (define delta : Delta
      (Entry-delta entry))

    (define result : Result
      (Delta-result delta))

    (define stat : Stat
      (Result-stat result))

    (define stage-in-lst : (Listof File-Interval)
      (Stat-stage-in-lst stat))

    (define size-byte : Exact-Nonnegative-Integer
      (sum-size stage-in-lst))

    (define size-gibit : Nonnegative-Real
      (* size-byte 8.0 9.313225746154785e-10))

    (define duration : Nonnegative-Real
      (Interval-duration (Stat-run stat)))

    (define throughput : Real
      (/ size-gibit duration))

    (define tp-lst : (Listof Real)
      (hash-ref t fn-name (λ () '())))

    (when (< throughput MAX-THROUGHPUT)
      (hash-set! t fn-name (cons throughput tp-lst))))
                

  (for-each proc-entry h)

  (hash->list t))

(: plot-throughput-density-fn (Throughput-Density-Fn-Data Path-String -> Void))
(define (plot-throughput-density-fn bwdn-data filename)

  (define rlst : (Listof renderer2d)
    (for/list ([pair : (Pairof String (Listof Real)) (in-list bwdn-data)])
      
      (define fn-name : String
        (car pair))

      (define sample : (Listof Real)
        (cdr pair))

      (density sample
               #:label fn-name
               #:color (pick-color fn-name))))

  (plot rlst
        #:x-label "Foreign Function throughput [GiBit/s]"
        #:y-label "Probability density"
        #:x-min 0
        #:x-max MAX-THROUGHPUT
        #:y-min 0
        #:width PLOT-WIDTH
        #:height PLOT-HEIGHT
        #:legend-anchor 'top-right
        #:out-kind 'png
        #:out-file filename)

  (void))


