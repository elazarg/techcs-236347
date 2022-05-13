Require Import Arith.
Require Import Lia.
Import Nat.


Load "./hoare".


(*
  euclid(a, b):
    while a != b do
      if a > b then
        a := a - b
      else
        b := b - a
 *)

Definition gt01 n m := if gt_dec n m then 1 else 0.
Definition ne01 n m := if eq_dec n m then 0 else 1.

Notation "[ e1 `-` e2 ]" := (expr_op e1 sub e2).
Notation "[ e1 `>` e2 ]" := (expr_op e1 gt01 e2).
Notation "[ e1 `!=` e2 ]" := (expr_op e1 ne01 e2).

Notation "$ v" := (expr_var v) (at level 7, format "$ v").
Notation "# n" := (expr_num n) (at level 7, format "# n").


Definition euclid_cmd :=
  while [$a `!=` $b]
        (if_then_else [$a `>` $b]
                      (assign a [$a `-` $b])
                      (assign b [$b `-` $a])).


(* Definition of divisibility + some syntactic sugar *)
Definition divides a b := exists k, a * k = b.
Notation "( a | b )" := (divides a b).



(* Control the behavior of `simpl` to allow more unfoldings.            *)
(*                                                                      *)
(* This should allow you to simplify a substitution term,               *)
(*   e.g. subst (fun s => s a + 1 = 2) a [$a `-` #1] s                  *)
(*        ( in other words, (a + 1 = 2)[a - 1 / a] )                    *)
(*     simplifies to                                                    *)
(*        s a - 1 + 1 = 2                                               *)
Arguments subst P v e /.
Arguments set s v / z.
Arguments var_eq_dec !v1 !v2.
Arguments gt01 n m / : simpl nomatch.
Arguments ne01 n m / : simpl nomatch.


(* Warm-up exercise:                               *)
(*                                                 *)
(*  {a = a0 /\ b = b0}  a := a - b  {a = a0 - b0}  *)
(*                                                 *)
Lemma warm_up a0 b0 : hoare (fun s => s a = a0 /\ s b = b0)
                            (assign a [$a `-` $b])
                            (fun s => s a = a0 - b0).
  (* Hint 1: use hoare_weaken_l (from hoare.v).
   * Hint 2: you can switch subgoals with Focus <num>. 
   *)





Module MainProof.

  Definition c := if_then_else [$a `>` $b]
                               (assign a [$a `-` $b])
                               (assign b [$b `-` $a]).

  Definition linv a0 b0 :=
    fun s => forall z, (z | a0) /\ (z | b0) <-> (z | s a) /\ (z | s b).

  (* ----  some free lemmas!  (you don't have to prove them)  ---- *)
  Lemma gt0_le x y : gt01 x y = 0 <-> x <= y.  Admitted.
  Lemma gt1_gt x y : gt01 x y <> 0 <-> x > y.  Admitted.
  Lemma div_sub a b z : (z | a) -> (z | b) -> (z | a - b).  Admitted.
  Lemma sub_div1 a b z : a >= b -> (z | a) -> (z | a - b) -> (z | b).  Admitted.
  Lemma sub_div2 a b z : a >= b -> (z | b) -> (z | a - b) -> (z | a).  Admitted.
    
  Lemma aux1 a0 b0 a b: (forall z, (z | a0) /\ (z | b0) <-> (z | a) /\ (z | b)) ->
                        a > b ->
                        forall z, (z | a0) /\ (z | b0) <-> (z | a - b) /\ (z | b).
  Admitted.

  Lemma aux2 a0 b0 a b: (forall z, (z | a0) /\ (z | b0) <-> (z | a) /\ (z | b)) ->
                        a < b ->
                        forall z, (z | a0) /\ (z | b0) <-> (z | a) /\ (z | b - a).
  Admitted.

  (* Hint 3: Use aux1 and aux2 to prove eucliv_inv.
   *         Then use euclid_inv to prove euclid_post.
   *         Time permitting, go back to aux1 and aux2 and prove them.
   *         Use the other lemmas where appropriate.
   *)
  
  Lemma euclid_inv a0 b0 : hoare (fun s => linv a0 b0 s /\ s a <> s b)
                                 c
                                 (linv a0 b0).




  Theorem euclid_post a0 b0 : hoare (fun s => s a = a0 /\ s b = b0)
                                    euclid_cmd
                                    (fun s => forall z, (z | a0) /\ (z | b0) <-> (z | s a)).

    
End MainProof.




