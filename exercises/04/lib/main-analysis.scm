(load "env.scm")
(load "keyword.scm")
(load "builtin.scm")
(load "analyzer.scm")

(define (eval exp env)
  ((analyze exp) env))

(define (analyze exp)
  (cond ((self-evaluating? exp) (analyze-self-evaluating exp))
        ((quoted? exp) (analyze-quoted exp))
        ((variable? exp) (analyze-variable exp))
        ((assignment? exp) (analyze-assignment exp))
        ((definition? exp) (analyze-definition exp))
        ((if? exp) (analyze-if exp))
        ((lambda? exp) (analyze-lambda exp))
        ((begin? exp) (analyze-sequence (begin-actions exp)))
        ((cond? exp) (analyze (cond->if exp)))
        ((application? exp) (analyze-application exp))
        (else (error "Unknown expression type -- ANALYZE " exp))))

; 这里将 eval 实现为一个采用 cond 的分情况分析。这样做的缺点是我们的过程只处理了若干种不同类型的表达式。
; 在大部分的 Lisp 实现里,针对表达式类型的分派都采用了数据导向的方式。这样用户可以更容易增加 eval 能分辨的表达式类型,而又不必修改 eval 的定义本身。


(define (apply-inner procedure arguments)
  (cond ((primitive-procedure? procedure)
          (apply-primitive-procedure procedure arguments))
        ((compound-procedure? procedure)
          (eval-sequence
            (procedure-body procedure)
            (extend-environment (procedure-parameters procedure)
                                arguments
                                (procedure-environment procedure))))
        (else
          (error "Unknown procedure type --  APPLY " procedure))))

; 过程参数，eval 使用

(define (list-of-values exps env)
  (if (no-operands? exps)
    '()
    (cons (eval (first-operand exps) env)
          (list-of-values (rest-operands exps) env))))

(define input-prompt ";;; M-Eval input: ")
(define output-prompt ";;; M-Eval values: ")
(define (driver-loop)
  (prompt-for-input input-prompt)
  (let ((input (read)))
    (let ((output (eval input the-global-environment)))
      (announce-output output-prompt)
      (user-print output)))
  (driver-loop))
(define (prompt-for-input string)
  (newline) (newline) (display string) (newline))
(define (announce-output string)
  (newline) (display string) (newline))
(define (user-print object)
  (if (compound-procedure? object)
    (display (list 'compound-procedure
                    (procedure-parameters object)
                    (procedure-body object)
                    '<procedure-env>))
    (display object)))

(define the-global-environment (setup-environment))
(driver-loop)
