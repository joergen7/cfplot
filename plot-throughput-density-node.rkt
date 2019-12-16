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

(provide Throughput-Density-Node-Data
         throughput-density-node-data
         plot-throughput-density-node)

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


(define-type Throughput-Density-Node-Data
  (Listof (Pairof String (Listof Real))))

(: throughput-density-node-data (History -> Throughput-Density-Node-Data))
(define (throughput-density-node-data h)

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
      (last (string-split (Result-node result) "@")))

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
      (hash-ref t node (λ () '())))

    (when (< throughput MAX-THROUGHPUT)
      (hash-set! t node (cons throughput tp-lst))))
                

  (for-each proc-entry h)

  (hash->list t))

(: plot-throughput-density-node (Throughput-Density-Node-Data Path-String -> Void))
(define (plot-throughput-density-node bwdn-data filename)

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


