Inductive Z : Type :=
| Pos : nat -> Z
| Zero : Z
| Neg : nat -> Z.

Definition neg (n: Z) : Z :=
match n with
| Pos k => Neg k
| Zero => Zero
| Neg k => Pos k
end.

Definition abs (n: Z) : Z :=
match n with
| Pos k => Pos k
| Zero => Zero
| Neg k => Pos k
end.

Definition succ (n: Z) : Z :=
match n with
| Pos k => Pos (S k)
| Zero => Pos O
| Neg O => Zero
| Neg (S n) => Neg n
end.

Definition pred (n: Z) : Z :=
match n with
| Pos (S n) => Pos n
| Pos O => Zero
| Zero => Neg O
| Neg n => Neg (S n)
end.

Theorem one_is_zero_succ : Pos O = succ Zero.
Proof.
  cbn. trivial.
Qed.

Theorem succ_S : forall n: nat, Pos (S n) = succ (Pos n).
Proof.
  destruct n; cbn; trivial. 
Qed.

Theorem minus_one_is_zero_pred : Neg O = pred Zero.
Proof.
  cbn. trivial.
Qed.

Theorem pred_S : forall n: nat, Neg (S n) = pred (Neg n).
Proof.
  destruct n; cbn; trivial. 
Qed.

Theorem Z_ind' (P : Z -> Prop) (base: P Zero) (suc: forall z: Z, P z -> P (succ z)) 
  (pre: forall z: Z, P z -> P (pred z)) : forall z: Z, P z.
Proof.
  intro z. destruct z.
  - induction n.
    + rewrite one_is_zero_succ. apply suc. assumption.
    + rewrite succ_S. apply suc. assumption.
  - assumption.
  - induction n.
    + rewrite minus_one_is_zero_pred. apply pre. assumption.
    + rewrite pred_S. apply pre. assumption.
Qed.

Theorem Z_ind'' (P : Z -> Prop) (base: P Zero) (base_pos: P (Pos O)) (base_neg: P (Neg O))
  (suc: forall n: nat, P (Pos n) -> P (Pos (S n))) 
  (pre: forall n: nat, P (Neg n) -> P (Neg (S n))) : forall z: Z, P z.
Proof.
  intro z. destruct z.
  - induction n.
    + assumption.
    + apply suc. assumption.
  - assumption.
  - induction n.
    + assumption.
    + apply pre. assumption.
Qed.

Theorem neg_neg: forall n : Z, neg (neg n) = n.
Proof.
  intro n. destruct n; cbn; reflexivity.
Qed.

Theorem abs_impotent: forall n : Z, abs n = abs (abs n).
Proof.
  intro n. destruct n; cbn; reflexivity.
Qed.

Theorem succ_pred : forall n: Z, succ (pred n) = n.
Proof.
  intro n. induction n.
  - destruct n; cbn; trivial.
  - cbn. trivial.
  - destruct n; cbn; trivial.
Qed.

Theorem pred_succ : forall n: Z, pred (succ n) = n.
Proof.
  intro n. induction n.
  - destruct n; cbn; trivial.
  - cbn. trivial.
  - destruct n; cbn; trivial.
Qed.







(* add *)

Fixpoint map_n {A: Type} (n: nat) (f: A -> A) (x: A) : A :=
match n with
| O => x
| S n' => f (map_n n' f x)
end.

Definition add (a b : Z) : Z :=
match a with 
| Pos n => map_n (S n) succ b
| Zero => b
| Neg n => map_n (S n) pred b
end.

Theorem add_r_zero : forall x: Z, add x Zero = x.
Proof.
  induction x using Z_ind''; trivial.
  - cbn; rewrite succ_S; f_equal; apply IHx.
  - cbn; rewrite pred_S; f_equal; apply IHx.
Qed.

Theorem add_r_succ : forall x y: Z, add x (succ y) = succ (add x y).
Proof.
  intros x y. revert x. induction x using Z_ind''; trivial.
  - cbn. rewrite pred_succ. rewrite succ_pred. trivial.
  - cbn in *. f_equal. apply IHx.
  - cbn in *. rewrite succ_pred. rewrite succ_pred in IHx. rewrite IHx. trivial.
Qed.

Theorem add_r_pred : forall x y: Z, add x (pred y) = pred (add x y).
Proof.
  intros x y. revert x. induction x using Z_ind''; trivial.
  - cbn. rewrite pred_succ. rewrite succ_pred. trivial.
  - cbn in *. rewrite pred_succ in *. rewrite IHx. trivial.
  - cbn in *. f_equal. apply IHx.
Qed.

Theorem add_sym: forall x y: Z, add x y = add y x.
Proof.
  intro x. induction x using Z_ind''; intro y.
  - rewrite add_r_zero. cbn. trivial.
  - cbn. rewrite one_is_zero_succ. rewrite add_r_succ. rewrite add_r_zero. trivial.
  - cbn. rewrite minus_one_is_zero_pred. rewrite add_r_pred.
    rewrite add_r_zero. trivial.
  - cbn. rewrite succ_S. rewrite add_r_succ. f_equal. apply IHx.
  - cbn. rewrite pred_S. rewrite add_r_pred. f_equal. apply IHx.
Qed.

Theorem neg_succ : forall x: Z, neg (succ x) = pred (neg x).
Proof.
  destruct x.
  - cbn. trivial.
  - cbn. trivial.
  - destruct n; cbn; trivial.
Qed.

Theorem neg_pred : forall x: Z, neg (pred x) = succ (neg x).
Proof.
  destruct x.
  - destruct n; cbn; trivial.
  - cbn. trivial.
  - cbn. trivial.
Qed.

Theorem add_pred_succ : forall x y: Z, add (pred x) (succ y) = add x y.
Proof.
  intros x y. rewrite add_r_succ. rewrite (add_sym (pred x) y). rewrite add_r_pred.
  rewrite succ_pred. rewrite add_sym. trivial.
Qed.

Theorem neg_is_add_inv : forall x: Z, add x (neg x) = Zero.
Proof.
  induction x using Z_ind''; trivial.
  - rewrite succ_S. rewrite neg_succ. rewrite add_sym. rewrite add_pred_succ.
    rewrite add_sym. assumption.
  - rewrite pred_S. rewrite neg_pred. rewrite add_pred_succ. assumption.
Qed.


Theorem add_l_succ : forall x y: Z, add (succ x) y = succ (add x y).
Proof.
  intros x y. rewrite (add_sym (succ x) y). rewrite add_r_succ. f_equal.
  apply add_sym.
Qed.

Theorem add_succ_swap : forall x y: Z,  add x (succ y) = add (succ x) y.
Proof.
  intros x y. rewrite add_r_succ. rewrite add_l_succ. trivial.
Qed.

Theorem add_l_pred : forall x y: Z, add (pred x) y = pred (add x y).
Proof.
  intros x y. rewrite (add_sym (pred x) y). rewrite add_r_pred. f_equal.
  apply add_sym.
Qed.

Theorem add_pred_swap : forall x y: Z, add x (pred y) = add (pred x) y.
Proof.
  intros x y. rewrite add_r_pred. rewrite add_l_pred. trivial.
Qed.

Theorem add_assoc : forall x y z: Z, add (add x y) z = add x (add y z).
Proof.
  intros x y z. revert y. induction x using Z_ind''; intro y.
  - cbn. trivial.
  - cbn. apply add_l_succ.
  - cbn. apply add_l_pred.
  - rewrite succ_S. rewrite add_l_succ. rewrite add_l_succ. rewrite add_l_succ. f_equal.
    apply IHx.
  - rewrite pred_S. rewrite add_l_pred. rewrite add_l_pred. rewrite add_l_pred. f_equal.
    apply IHx.
Qed.

Theorem add_one : forall x: Z, add x (Pos O) = succ x.
Proof.
  intro x. rewrite one_is_zero_succ. rewrite add_r_succ. rewrite add_r_zero. trivial.
Qed.

Theorem add_minus_one : forall x: Z, add x (Neg O) = pred x.
Proof.
  intro x. rewrite minus_one_is_zero_pred. rewrite add_r_pred.
  rewrite add_r_zero. trivial.
Qed.

Theorem add_neg : forall x y: Z, add (neg x) (neg y) =  neg (add x y).
Proof.
  intro x. induction x using Z_ind''; intro y; trivial.
  - cbn. symmetry. apply neg_succ.
  - cbn. symmetry. apply neg_pred.
  - rewrite succ_S. rewrite add_l_succ. rewrite neg_succ. rewrite neg_succ. rewrite <- IHx.
    rewrite add_l_pred. f_equal.
  - rewrite pred_S. rewrite add_l_pred, neg_pred, neg_pred. rewrite <- IHx, add_l_succ.
    f_equal.
Qed.

Theorem add_r_neg : forall x y: Z, add x (neg y) =  neg (add (neg x) y).
Proof.
  intro x. induction x using Z_ind''; intro y; trivial.
  - cbn. rewrite neg_pred. trivial.
  - cbn. rewrite neg_succ. trivial.
  - rewrite succ_S. rewrite add_l_succ. rewrite IHx. rewrite neg_succ, add_l_pred, neg_pred.
    f_equal. 
  - rewrite pred_S, add_l_pred, neg_pred, add_l_succ, neg_succ. 
    f_equal. apply IHx.
Qed.

Theorem add_l_neg : forall x y: Z, add (neg x) y =  neg (add x (neg y)).
Proof.
  intros x y. rewrite add_sym. rewrite add_r_neg. rewrite add_sym. trivial.
Qed.







(* mul *)
  
Definition mul (a b: Z) : Z :=
match a with 
| Pos n => map_n (S n) (add b) Zero
| Zero => Zero
| Neg n => neg (map_n (S n) (add b) Zero)
end.

Definition id {A: Type} (x: A) := x.

Theorem mul_r_zero : forall x: Z, mul x Zero = Zero.
Proof.
  intros x. destruct x.
  - cbn. induction n; cbn; auto.
  - cbn. auto.
  - cbn. induction n; cbn; auto.
Qed.

Theorem mul_r_one : forall x: Z, mul x (Pos O) = x.
Proof.
  induction x using Z_ind''; trivial.
  - cbn. rewrite succ_S. f_equal. assumption.
  - cbn. rewrite pred_S. rewrite neg_succ. f_equal. assumption. 
Qed.

Theorem mul_r_minus_one : forall x: Z, mul x (Neg O) = neg x.
Proof.
  induction x using Z_ind''; trivial.
  - cbn. rewrite pred_S. f_equal. assumption.
  - cbn. rewrite succ_S. rewrite neg_pred. f_equal. assumption. 
Qed.

Theorem mul_r_succ : forall x y: Z, mul x (succ y) = add (mul x y) x.
Proof.
  intros x y. revert x. induction x using Z_ind''; trivial.
  - cbn. rewrite add_r_zero. rewrite add_r_zero. rewrite add_one. trivial.
  - cbn. rewrite add_r_zero. rewrite add_r_zero. rewrite add_minus_one. apply neg_succ.
  - cbn in *. rewrite IHx. rewrite add_l_succ. rewrite succ_S.
    rewrite add_r_succ. f_equal. rewrite add_assoc. rewrite add_assoc.
    rewrite add_assoc. trivial.
  - cbn in *. rewrite pred_S. rewrite <- add_neg, IHx, <- add_neg,  <- add_neg.
    rewrite <- add_neg. rewrite add_r_pred, neg_succ, add_l_pred. f_equal.
    rewrite add_assoc, add_assoc, add_assoc. trivial.
Qed.

Theorem mul_r_pred : forall x y: Z, mul x (pred y) = add (mul x y) (neg x).
Proof.
  intros x y. revert x. induction x using Z_ind''; trivial.
  - cbn. rewrite add_r_zero. rewrite add_r_zero. rewrite add_minus_one. trivial.
  - cbn. rewrite add_r_zero, add_r_zero. rewrite add_one. apply neg_pred.
  - cbn in *. rewrite IHx. rewrite add_l_pred. rewrite pred_S.
    rewrite add_r_pred. f_equal. rewrite add_assoc. rewrite add_assoc.
    rewrite add_assoc. trivial.
  - cbn in *. rewrite succ_S. rewrite <- add_neg, IHx, <- add_neg,  <- add_neg.
    rewrite <- add_neg. rewrite add_r_succ, neg_pred, add_l_succ. f_equal.
    rewrite add_assoc, add_assoc, add_assoc. trivial.
Qed.

Theorem mul_sym : forall x y: Z, mul x y = mul y x.
Proof.
  intros x. induction x using Z_ind''; intro y.
  - rewrite mul_r_zero. cbn. trivial.
  - rewrite mul_r_one. cbn. rewrite add_r_zero. trivial.
  - rewrite mul_r_minus_one. cbn. rewrite add_r_zero. trivial.
  - rewrite succ_S. rewrite mul_r_succ. rewrite <- IHx. cbn. rewrite add_assoc.
    f_equal. apply add_sym.
  - rewrite pred_S. rewrite mul_r_pred. rewrite <- IHx. cbn.
    rewrite <- add_neg, <- add_neg. rewrite add_sym. trivial.
Qed.

Theorem mul_l_succ : forall x y: Z, mul (succ x) y = add (mul x y) y.
Proof.
  intros x y. rewrite mul_sym. rewrite mul_r_succ. rewrite (mul_sym x y). trivial.
Qed.

Theorem mul_l_pred : forall x y: Z, mul (pred x) y = add (mul x y) (neg y).
Proof.
  intros x y. rewrite mul_sym. rewrite mul_r_pred. rewrite (mul_sym x y). trivial.
Qed.

Theorem mul_r_neg : forall x y: Z, mul x (neg y) = neg (mul x y).
Proof.
  intros x. induction x using Z_ind'; intro y; trivial.
  - rewrite mul_l_succ, mul_l_succ.
    rewrite IHx. rewrite add_neg. trivial.
  - rewrite mul_l_pred, mul_l_pred, IHx.
    rewrite add_r_neg, neg_neg. trivial.
Qed.

Theorem mul_l_neg : forall x y: Z, mul (neg x) y = neg (mul x y).
Proof.
  intros x y. rewrite mul_sym, mul_r_neg, mul_sym. trivial.
Qed.

Theorem mul_neg : forall x y: Z, mul (neg x) (neg y) = mul x y.
Proof.
  intros x y. rewrite mul_r_neg, mul_l_neg, neg_neg. trivial.
Qed.

Theorem mul_neg_swap : forall x y: Z, mul (neg x) y = mul x (neg y).
Proof.
  intros x y. rewrite mul_r_neg, mul_l_neg. trivial.
Qed.

Theorem mul_dist_add : forall x y z: Z, mul x (add y z) = add (mul x y) (mul x z).
Proof.
  intros x y z. revert x. induction x using Z_ind'; trivial.
  - rewrite mul_l_succ, mul_l_succ, mul_l_succ. rewrite IHx.
    rewrite add_assoc, add_assoc. rewrite (add_sym (mul x z) (add y z)). 
    rewrite (add_sym (mul x z) z). rewrite add_assoc. trivial.
  - rewrite mul_l_pred, mul_l_pred, mul_l_pred. rewrite IHx.
    rewrite add_assoc, add_assoc. rewrite (add_sym (neg y) (add (mul x z) (neg z))). 
    rewrite (add_sym y z). rewrite add_assoc. rewrite add_neg. trivial.
Qed. 

Theorem mul_assoc : forall x y z: Z, mul (mul x y) z = mul x (mul y z).
Proof.
  intros x y z. revert y. induction x using Z_ind'; intro y; trivial.
  - rewrite mul_l_succ. rewrite mul_l_succ.
    rewrite mul_sym, mul_dist_add. rewrite <- IHx. f_equal; apply mul_sym.
  - rewrite mul_l_pred, mul_l_pred. rewrite add_r_neg. rewrite mul_l_neg.
    rewrite add_r_neg. f_equal. rewrite mul_sym, mul_dist_add. f_equal.
    + rewrite <- IHx. rewrite mul_r_neg. f_equal. rewrite mul_sym. trivial.
    + apply mul_sym.
Qed.



(* uniqeu representation *)

Record Izomorphism (A B: Type) := Izo {
  izo_fun : A -> B;
  izo_inv : B -> A;
  izo_id  : forall x: A, izo_inv (izo_fun x) = x;
  izo_id' : forall x: B, izo_fun (izo_inv x) = x;
}.

Record Integer := Int {
  v : nat * nat;
  one_zero : let (x, y) := v in (x = O) \/ (y = O); 
}.

Fixpoint norm (x y : nat) : (nat * nat) :=
match x, y with
| S x, S y => norm x y
| _, _ => (x, y)
end.

Definition norm' (p: nat * nat) : (nat * nat) := 
  let (x, y) := p in norm x y.

Theorem norm_is_normal (p: nat * nat) : let (x, y) := (norm' p) in (x = O) \/ (y = O).
Proof.
  destruct p. revert n0. induction n.
  - cbn. left. reflexivity.
  - destruct n0.
    + cbn. right. reflexivity.
    + cbn. apply IHn.
Qed.

Theorem norm_is_impotent : forall p: nat * nat, norm' p = norm' (norm' p).
Proof.
  intro p. destruct p. revert n0. induction n; intro n'.
  - cbn. reflexivity.
  - destruct n'; cbn.
    + reflexivity.
    + apply IHn.
Qed.

Definition get_integer (p: nat * nat) : Integer := {|
  v := norm' p;
  one_zero := norm_is_normal p;
|}.

Definition Z_to_Integer' (z : Z) : nat*nat := 
match z with 
| Pos n => (S n, O)
| Zero => (O, O) 
| Neg n => (O, S n)
end.

Theorem Z_to_Integer_proof : forall z: Z, let (x, y) := (Z_to_Integer' z) in (x = O) \/ (y = O).
Proof.
  intro z. destruct z; cbn; auto.
Defined.

Definition Z_to_Integer (z : Z) : Integer := {|
  v := Z_to_Integer' z;
  one_zero := Z_to_Integer_proof z;
|}.

Definition Integer_to_Z (i : Integer) : Z :=
match v i with
| (O, O) => Zero
| (S n, O) => Pos n
| (O, S n) => Neg n
| (S n, S n') => Zero
end.


