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

(require racket/cmdline

         (only-in "history.rkt"
                  read-history
                  History)

         (only-in "plot-selectivity.rkt"
                  Selectivity-Data
                  selectivity-data
                  plot-selectivity)

         (only-in "plot-file-reuse.rkt"
                  File-Reuse-Data
                  file-reuse-data
                  plot-file-reuse)

         (only-in "plot-lipka.rkt"
                  Lipka-Data
                  lipka-data
                  plot-lipka)

         (only-in "plot-dependency.rkt"
                  Digraph
                  dependency-data
                  plot-digraph)

         (only-in "plot-bandwidth-density.rkt"
                  Bandwidth-Data
                  bandwidth-data
                  plot-bandwidth)

         (only-in "plot-throughput-density.rkt"
                  Throughput-Data
                  plot-throughput
                  throughput-data)

         (only-in "plot-bandwidth-scatter.rkt"
                  Bandwidth-Scatter-Data
                  plot-bandwidth-scatter
                  bandwidth-scatter-data)

         (only-in "plot-throughput-scatter.rkt"
                  Throughput-Scatter-Data
                  throughput-scatter-data
                  plot-throughput-scatter)

         (only-in "plot-stage-in-bandwidth-density-node.rkt"
                  Stage-In-Bandwidth-Density-Node-Data
                  stage-in-bandwidth-density-node-data
                  plot-stage-in-bandwidth-density-node)

         (only-in "plot-stage-out-bandwidth-density-node.rkt"
                  Stage-Out-Bandwidth-Density-Node-Data
                  stage-out-bandwidth-density-node-data
                  plot-stage-out-bandwidth-density-node)

         (only-in "plot-throughput-density-node.rkt"
                  Throughput-Density-Node-Data
                  throughput-density-node-data
                  plot-throughput-density-node)
         )



(: process-file (Path-String -> Void))
(define (process-file history-file)

  (define prefix : String
    (assert
     (car (assert
           (regexp-match #rx"[^\\.]*" history-file)
           pair?))
     string?))

  (time
   ;; History -------------------------------------------------

   (displayln (format "reading history file ~s ..." history-file))

   (define h : History
     (read-history history-file))

   (displayln (format "~a history entries read." (length h)))


   ;; Selectivity ---------------------------------------------

   (displayln "Selectivity ...")

   (define sel-data : Selectivity-Data
     (selectivity-data h))

   (define selectivity-file : String
     (string-append prefix "-selectivity.png"))

   (plot-selectivity sel-data selectivity-file)


   ;; File Reuse ----------------------------------------------

   (displayln "File reuse ...")

   (define fr-data : File-Reuse-Data
     (file-reuse-data h))

   (define file-reuse-file : String
     (string-append prefix "-file-reuse.png"))

   (plot-file-reuse fr-data file-reuse-file)


   ;; Lipka graph ----------------------------------------------

   (displayln "Lipka plot ...")

   (define l-data : Lipka-Data
     (lipka-data h))

   (define lipka-file : String
     (string-append prefix "-lipka.png"))

   (plot-lipka l-data lipka-file)


   ;; Dependency graph ----------------------------------------

   (displayln "Dependency graph ...")

   (define digraph : Digraph
     (dependency-data h))

   (define dep-file : String
     (string-append prefix "-dep.dot"))

   (plot-digraph digraph dep-file)


   ;; Bandwidth -----------------------------------------------

   (displayln "Bandwidth density ...")

   (define bw-data : Bandwidth-Data
     (bandwidth-data h))

   (define bandwidth-file : String
     (string-append prefix "-bandwidth-density.png"))

   (plot-bandwidth bw-data bandwidth-file)


   ;; Throughput density ----------------------------------------------

   (displayln "Throughput density ...")

   (define tp-data : Throughput-Data
     (throughput-data h))

   (define throughput-file : String
     (string-append prefix "-throughput-density.png"))

   (plot-throughput tp-data throughput-file)



   ;; Bandwidth scatter plot ----------------------------------

   (displayln "Bandwidth scatter plot ...")

   (define bws-data : Bandwidth-Scatter-Data
     (bandwidth-scatter-data h))

   (define bandwidth-scatter-file : String
     (string-append prefix "-bandwidth-scatter.png"))

   (plot-bandwidth-scatter bws-data
                           bandwidth-scatter-file)


   ;; Foreign function throughput scatter plot ----------------

   (displayln "Foreign function throughput scatter plot ...")

   (define tps-data : Throughput-Scatter-Data
     (throughput-scatter-data h))

   (define throughput-scatter-file : String
     (string-append prefix "-throughput-scatter.png"))

   (plot-throughput-scatter tps-data
                            throughput-scatter-file)



   ;; Stage in bandwidth density per node ----------------

   (displayln "Stage in bandwidth density per node ...")

   (define sibwn-data : Stage-In-Bandwidth-Density-Node-Data
     (stage-in-bandwidth-density-node-data h))

   (define stage-in-bandwidth-density-node-file : String
     (string-append prefix "-stage-in-bandwidth-density-node.png"))

   (plot-stage-in-bandwidth-density-node sibwn-data
                                         stage-in-bandwidth-density-node-file)



   ;; Stage out bandwidth density per node ----------------

   (displayln "Stage out bandwidth density per node ...")

   (define sobwn-data : Stage-Out-Bandwidth-Density-Node-Data
     (stage-out-bandwidth-density-node-data h))

   (define stage-out-bandwidth-density-node-file : String
     (string-append prefix "-stage-out-bandwidth-density-node.png"))

   (plot-stage-out-bandwidth-density-node sobwn-data
                                          stage-out-bandwidth-density-node-file)


   ;; Throughput density per node ----------------

   (displayln "Throughput density per node ...")

   (define tpn-data : Throughput-Density-Node-Data
     (throughput-density-node-data h))

   (define throughput-density-node-file : String
     (string-append prefix "-throughput-density-node.png"))

   (plot-throughput-density-node tpn-data
                                 throughput-density-node-file)




   ))





  




(define file-lst : (Listof Any)
  (assert
   (command-line #:program "cfplot"
                 ; #:argv '("2018-12-04-variant-call-linuxpool.json")
                 #:args    file-lst
                 file-lst)
   list?))

(for-each (λ ([f : Any]) (process-file (assert f string?)))
          file-lst)

