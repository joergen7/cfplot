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

(require (only-in typed/json
                  JSExpr
                  read-json
                  write-json)
         (only-in racket/cmdline
                  command-line))

(: read-history-proc (Input-Port -> JSExpr))
(define (read-history-proc inp)
  (define x : (U JSExpr EOF)
    (read-json inp))
  (if (eof-object? x)
      (error "Input file is empty.")
      x))

(: translate-stat (JSExpr -> JSExpr))
(define (translate-stat stat)

  (define run : JSExpr
    (hash-ref (assert stat hash?) 'run))

  (define sched : JSExpr
    (hash-ref (assert stat hash?) 'sched))

  (define stage-in-lst : JSExpr
    (hash-ref (assert stat hash?) 'stage_in_lst))

  (define stage-out-lst : JSExpr
    (hash-ref (assert stat hash?) 'stage_out_lst))

  (hasheq 'run run
          'sched sched
          'stage_in_lst stage-in-lst
          'stage_out_lst stage-out-lst))
  

(: translate-result (JSExpr -> JSExpr))
(define (translate-result result)

  (define ret-bind-lst : JSExpr
    (hash-ref (assert result hash?) 'ret_bind_lst))

  (define stat : JSExpr
    (hash-ref (assert result hash?) 'stat))

  (define status : JSExpr
    (hash-ref (assert result hash?) 'status))

  (define node : JSExpr
    (hash-ref (assert stat hash?) 'node))

  (hasheq 'ret_bind_lst ret-bind-lst
          'node node
          'status status
          'stat (translate-stat stat)))

    

(: translate-delta (JSExpr -> JSExpr))
(define (translate-delta delta)
  
  (define app-id : JSExpr
    (hash-ref (assert delta hash?) 'app_id))

  (define result : JSExpr
    (hash-ref (assert delta hash?) 'result))
                      
  (hasheq 'app_id app-id 'result (translate-result result)))
    

(: translate-app-delta-pair (JSExpr -> JSExpr))
(define (translate-app-delta-pair pair)
  
  (define app : JSExpr
    (hash-ref (assert pair hash?) 'app))

  (define delta : JSExpr
    (hash-ref (assert pair hash?) 'delta))

  (hasheq 'app app 'delta (translate-delta delta)))



(: process-file (String -> Any))
(define (process-file path)

  (define root : JSExpr
    (call-with-input-file
        path
      read-history-proc
      #:mode 'binary))

  (define history-list : JSExpr
    (hash-ref (assert root hash?) 'history))

  (define translated-root : JSExpr
    (hasheq 'history (map translate-app-delta-pair (assert history-list list?))))

  (write-json translated-root))


(define file-lst : (Listof Any)
  (assert
   (command-line #:program "translate-304-305"
                 ; #:argv '("examples/2018-12-17-chip-seq-x240-1x4.json")
                 #:args    file-lst
                 file-lst)
   list?))

(for-each (λ ([f : Any]) (process-file (assert f string?)))
          file-lst)




