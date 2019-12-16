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

(provide pick-color
         pick-light-color
         pick-symbol)



(require (only-in typed/racket/class
                  make-object)

         (only-in typed/racket/draw
                  color%
                  Color%))

(require/typed racket/base
               [sha1-bytes (-> Bytes Bytes)])



(define SYM-LST : (Listof Char) '(#\+ #\× #\∗ #\• #\- #\△ #\★ #\◇ #\∘ #\÷ #\◃ #\▹ #\· #\† #\‡))


(: pick-color (String -> (Instance Color%)))
(define (pick-color s)

  (define h : Bytes
    (sha1-bytes (string->bytes/utf-8 s)))

  (define r : Byte
    (bytes-ref h 0))

  (define g : Byte
    (bytes-ref h 1))

  (define b : Byte
    (bytes-ref h 2))
  
  (make-object color% r g b))

(: pick-light-color (String -> (Instance Color%)))
(define (pick-light-color s)

  (define h : Bytes
    (sha1-bytes (string->bytes/utf-8 s)))

  (define r : Byte
    (bytes-ref h 0))

  (define g : Byte
    (bytes-ref h 1))

  (define b : Byte
    (bytes-ref h 2))
  
  (make-object color% (assert (+ 128 (quotient r 2)) byte?)
                      (assert (+ 128 (quotient g 2)) byte?)
                      (assert (+ 128 (quotient b 2)) byte?)))


(: pick-symbol (String -> Char))
(define (pick-symbol s)

  (define h : Integer
    (car (bytes->list (sha1-bytes (string->bytes/utf-8 s)))))

  (define len : Integer
    (length SYM-LST))

  (list-ref SYM-LST (modulo h len)))