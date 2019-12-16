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
         read-history
         sum-size
         t-start
         t-end
         lambda-name-lst

         ; predicates
         history?
         lang?
         type?

         ; type defintions
         History
         Lang
         Type

         ; structure definitions
         (struct-out Entry)
         (struct-out App)
         (struct-out Bind)
         (struct-out Lambda)
         (struct-out TArg)
         (struct-out Delta)
         (struct-out Result)
         (struct-out Stat)
         (struct-out Interval)
         (struct-out File-Interval))

;;===============================================================
;; Requirements
;;===============================================================

(require (only-in typed/json
                  JSExpr
                  read-json))


;;===============================================================
;; Type Definitions
;;===============================================================

(define-type History
  (Listof Entry))

(define-predicate history? History)

(define-type Lang
  (U 'Bash
     'Erlang
     'Java
     'Matlab
     'Octave
     'Perl
     'Python
     'R
     'Racket))

(define-predicate lang? Lang)


(define-type Type
  (U 'Bool
     'Str
     'File))

(define-predicate type? Type)


;;===============================================================
;; Structure Definitions
;;===============================================================

(struct Entry ([app   : App]
               [delta : Delta])
  #:prefab)

(struct App ([app-id       : String]
             [arg-bind-lst : (Listof Bind)]
             [lambda       : Lambda])
  #:prefab)

(struct Bind ([arg-name : String]
              [value    : (U String (Listof String))])
  #:prefab)

(struct Lambda ([name         : String]
                [arg-type-lst : (Listof TArg)]
                [ret-type-lst : (Listof TArg)]
                [lang         : Lang]
                [script       : String])
  #:prefab)
                
(struct TArg ([name  : String]
              [type  : Type]
              [list? : Boolean])
  #:prefab)

(struct Delta ([app-id : String]
               [result : Result])
  #:prefab)

(struct Result ([ret-bind-list : (Listof Bind)]
                [node          : String]
                [stat          : Stat])
  #:prefab)

(struct Stat ([run           : Interval]
              [sched         : Interval]
              [stage-in-lst  : (Listof File-Interval)]
              [stage-out-lst : (Listof File-Interval)])
  #:prefab)

(struct Interval ([t-start  : Real]              ; in seconds from 1970
                  [duration : Nonnegative-Real]) ; in seconds
  #:prefab)

(struct File-Interval ([t-start  : Real]                       ; in seconds from 1970
                       [duration : Nonnegative-Real]           ; in seconds
                       [filename : String]
                       [size     : Exact-Nonnegative-Integer]) ; in Byte
  #:prefab)


;;===============================================================
;; API functions
;;===============================================================


(: read-history (-> Path-String History))
(define (read-history path)

  (: decode-file-interval (-> HashTableTop File-Interval))
  (define (decode-file-interval i)

    (define t-start : Real
      (* (assert (string->number (assert (hash-ref i 't_start) string?)) exact-integer?)
         0.000000001))

    (define duration : Nonnegative-Real
      (* (assert (string->number (assert (hash-ref i 'duration) string?)) exact-nonnegative-integer?)
         0.000000001))

    (define filename : String
      (assert (hash-ref i 'filename) string?))

    (define size : Exact-Nonnegative-Integer
      (assert (string->number (assert (hash-ref i 'size) string?)) exact-nonnegative-integer?))

    (File-Interval t-start duration filename size))
    

  (: decode-interval (-> HashTableTop Interval))
  (define (decode-interval i)

    (define t-start : Real
      (* (assert (string->number (assert (hash-ref i 't_start) string?)) exact-integer?)
         0.000000001))

    (define duration : Nonnegative-Real
      (* (assert (string->number (assert (hash-ref i 'duration) string?)) exact-nonnegative-integer?)
         0.000000001))

    (Interval t-start duration))

  (: decode-stat (-> HashTableTop Stat))
  (define (decode-stat stat)

    (define run : Interval
      (decode-interval (assert (hash-ref stat 'run) hash?)))

    (define sched : Interval
      (decode-interval (assert (hash-ref stat 'sched) hash?)))

    (define stage-in-lst : (Listof File-Interval)
      (for/list ([stage-in : Any (in-list (assert (hash-ref stat 'stage_in_lst) list?))])
        (decode-file-interval (assert stage-in hash?))))

    (define stage-out-lst : (Listof File-Interval)
      (for/list ([stage-out : Any (in-list (assert (hash-ref stat 'stage_out_lst) list?))])
        (decode-file-interval (assert stage-out hash?))))

    (Stat run sched stage-in-lst stage-out-lst))

  (: decode-result (-> HashTableTop Result))
  (define (decode-result result)

    (define node : String
      (assert (hash-ref result 'node) string?))

    (define ret-bind-lst : (Listof Bind)
      (for/list ([ret-bind : Any (in-list (assert (hash-ref result 'ret_bind_lst) list?))])
        (decode-bind (assert ret-bind hash?))))

    (define stat : Stat
      (decode-stat (assert (hash-ref result 'stat) hash?)))

    (Result ret-bind-lst node stat))

  (: decode-targ (-> HashTableTop TArg))
  (define (decode-targ targ)

    (define arg-name : String
      (assert (hash-ref targ 'arg_name) string?))

    (define arg-type : Type
      (assert (string->symbol (assert (hash-ref targ 'arg_type) string?)) type?))

    (define is-list : Boolean
      (assert (hash-ref targ 'is_list) boolean?))

    (TArg arg-name arg-type is-list))

  (: decode-lambda (-> HashTableTop Lambda))
  (define (decode-lambda lam)

    (define lambda-name : String
      (assert (hash-ref lam 'lambda_name) string?))

    (define arg-type-lst : (Listof TArg)
      (for/list ([targ (in-list (assert (hash-ref lam 'arg_type_lst) list?))])
        (decode-targ (assert targ hash?))))

    (define ret-type-lst : (Listof TArg)
      (for/list ([targ (in-list (assert (hash-ref lam 'ret_type_lst) list?))])
        (decode-targ (assert targ hash?))))

    (define lang : Lang
      (assert (string->symbol (assert (hash-ref lam 'lang) string?)) lang?))

    (define script : String
      (assert (hash-ref lam 'script) string?))

    (Lambda lambda-name arg-type-lst ret-type-lst lang script))
  
  (: decode-bind (-> HashTableTop Bind))
  (define (decode-bind bind)
    
    (define arg-name : String
      (assert (hash-ref (assert bind hash?) 'arg_name) string?))
    
    (define value : Any
      (hash-ref (assert bind hash?) 'value))

    (if (list? value)
        (Bind arg-name (ann (for/list ([v : Any (in-list value)]) (assert v string?)) (Listof String)))
        (Bind arg-name (assert value string?))))
          

   
  (: decode-entry (HashTableTop -> Entry))
  (define (decode-entry entry-obj)

    (define app : HashTableTop
      (assert (hash-ref entry-obj 'app) hash?))
    
    (define delta : HashTableTop
      (assert (hash-ref (assert entry-obj hash?) 'delta) hash?))
    
    (Entry (App (assert (hash-ref app 'app_id) string?)
                (for/list ([arg-bind : Any (in-list (assert (hash-ref app 'arg_bind_lst) list?))])
                  (decode-bind (assert arg-bind hash?)))
                (decode-lambda (assert (hash-ref app 'lambda) hash?)))
           (Delta (assert (hash-ref delta 'app_id) string?)
                  (decode-result (assert (hash-ref delta 'result) hash?)))))
                                         
  
  (: read-history-proc (-> Input-Port (Listof Entry)))
  (define (read-history-proc in)
    
    (define json-expr : (U JSExpr EOF)
      (read-json in))

    (define pair-lst-unfiltered : (Listof Any)
      (assert (hash-ref (assert json-expr hash?) 'history) list?))

    (: ok? (Any -> Boolean))
    (define (ok? pair)

      (define delta : Any
        (hash-ref (assert pair hash?) 'delta))

      (define result : Any
        (hash-ref (assert delta hash?) 'result))

      (define status : Any
        (hash-ref (assert result hash?) 'status))
        
      (equal? "ok" status))

    (define pair-lst : (Listof Any)
      (filter ok? pair-lst-unfiltered))
    
    (for/list ([pair : Any (in-list pair-lst)])
      (decode-entry (assert pair hash?))))

  (call-with-input-file path
    read-history-proc
    #:mode 'binary))

(: sum-size ((Listof File-Interval) -> Exact-Nonnegative-Integer))
(define (sum-size stage-lst)
  (for/fold ([s : Exact-Nonnegative-Integer 0])
            ([x : File-Interval (in-list stage-lst)])
    (+ s (File-Interval-size x))))


(: t-start (History -> Real))
(define (t-start h)

  (for/fold ([acc : Real +inf.0])
            ([entry : Entry (in-list h)])

    (define delta : Delta
      (Entry-delta entry))

    (define result : Result
      (Delta-result delta))

    (define stat : Stat
      (Result-stat result))

    (define sched : Interval
      (Stat-sched stat))

    (define t0 : Real
      (Interval-t-start sched))

    (if (< t0 acc)
        t0
        acc)))

(: t-end (History -> Real))
(define (t-end h)

  (for/fold ([acc : Real -inf.0])
            ([entry : Entry (in-list h)])

    (define delta : Delta
      (Entry-delta entry))

    (define result : Result
      (Delta-result delta))

    (define stat : Stat
      (Result-stat result))

    (define sched : Interval
      (Stat-sched stat))

    (define t0 : Real
      (+ (Interval-t-start sched)
         (Interval-duration sched)))

    (if (> t0 acc)
        t0
        acc)))

(: lambda-name-lst (History -> (Listof String)))
(define (lambda-name-lst h)

  (for/fold ([acc : (Listof String) '()])
            ([entry : Entry (in-list h)])

    (define app : App
      (Entry-app entry))

    (define lambda : Lambda
      (App-lambda app))

    (define lambda-name : String
      (Lambda-name lambda))

    (if (member lambda-name acc)
        acc
        (cons lambda-name acc))))

(module+ test

  (require (only-in typed/rackunit
                    check-equal?))

  (define fi1 : File-Interval
    (File-Interval 12 3 "bla" 4))

  (define fi2 : File-Interval
    (File-Interval 56 7 "blub" 8))

  (define entry1 : Entry
    (Entry (App "123"
                '()
                (Lambda "f"
                        '()
                        (list (TArg "out" 'Str #f))
                        'Bash
                        "bla"))
           (Delta "123"
                  (Result (list (Bind "out" "blub"))
                          "wrk@x240"
                          (Stat (Interval 45.0 9.0)
                                (Interval 42.0 15.0)
                                '()
                                '())))))

  (define entry2 : Entry
    (Entry (App "abc"
                '()
                (Lambda "g"
                        '()
                        (list (TArg "z" 'Str #f))
                        'Python
                        "bla"))
           (Delta "abc"
                  (Result (list (Bind "z" "blub"))
                          "wrk@alex"
                          (Stat (Interval 35.0 9.0)
                                (Interval 32.0 15.0)
                                '()
                                '())))))

  (check-equal? (sum-size '()) 0)
  (check-equal? (sum-size (list fi1)) 4)
  (check-equal? (sum-size (list fi1 fi2)) 12)
  
  (check-equal? (t-start '()) +inf.0)
  (check-equal? (t-start (list entry1)) 42.0)
  (check-equal? (t-start (list entry2)) 32.0)
  (check-equal? (t-start (list entry1 entry2)) 32.0)

  (check-equal? (t-end '()) -inf.0)
  (check-equal? (t-end (list entry1)) 57.0)
  (check-equal? (t-end (list entry2)) 47.0)
  (check-equal? (t-end (list entry1 entry2)) 57.0))


