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