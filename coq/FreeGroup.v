Require Import Coq.Program.Equality.
Require Import Coq.Bool.Bool.
Require Import Coq.Lists.List.
Require Import StrictProp.
Import ListNotations.

Class Group (A : Type) := GroupDef {
  zero      : A;
  op        : A -> A -> A;
  inv       : A -> A;
  eqf       : A -> A -> bool;
  left_id   : forall x: A, op zero x = x;
  right_id  : forall x: A, op x zero = x;
  left_inv  : forall x: A, op (inv x) x = zero;
  right_inv : forall x: A, op x (inv x) = zero;
  op_assoc  : forall x y z: A, op (op x y) z = op x (op y z);
  eqf_eq    : forall x y, reflect (x = y) (eqf x y)
}.

Lemma eqf_refl {A: Type} `{Group A} (x : A) : eqf x x = true.
Proof.
  destruct (eqf_eq x x); auto.
Qed.

Definition eqf_true_iff {A: Type} `{Group A} {x y: A} : eqf x y = true <-> x = y.
Proof.
  destruct (eqf_eq x y); split; auto. intros F. discriminate.
Qed.

Definition eqf_false_iff {A: Type} `{Group A} {x y: A} : eqf x y = false <-> x <> y.
Proof.
  split.
  - intros H0 H1. subst. rewrite eqf_refl in H0. discriminate.
  - intros H0. destruct (eqf_eq x y); auto. subst. contradiction.
Defined.

Lemma eqf_sym {A: Type} `{Group A} (x y: A) : eqf x y = eqf y x.
Proof.
  destruct (eqf_eq x y).
  - subst. rewrite eqf_refl. auto.
  - assert (y <> x) by (apply not_eq_sym; auto). rewrite <- eqf_false_iff in H0.
    rewrite H0. auto.
Qed.


(* Notation "a @ b" := (op a b) (at level 51, right associativity).
Notation "c ^" := (inv c) (at level 40). *)

Definition sub {A: Type} `{Group A} (x y: A) := op x (inv y).

Definition CanonFreeGroup (A: Type) `{Group A} := list (bool*A).

Inductive Normalized {A: Type} `{Group A} : CanonFreeGroup A -> Prop :=
| NNil   : Normalized []
| NSingl : forall (b : bool) (v : A), Normalized [(b, v)]
| NCons  : forall (b b': bool) (v v' : A) (x: CanonFreeGroup A), 
            v <> v' \/ b = b' -> Normalized ((b', v') :: x) ->
            Normalized ((b, v) :: (b', v') :: x).

Inductive NonEmptyFreeGroup (A: Type) `{Group A} :=
| Singl  : bool -> A -> NonEmptyFreeGroup A
| Switch : forall x: A, Squash (x <> zero) -> NonEmptyFreeGroup A -> NonEmptyFreeGroup A
| Stay   : A -> NonEmptyFreeGroup A -> NonEmptyFreeGroup A.

Arguments Switch {A H}.
Arguments Stay {A H}.
Arguments Singl {A H}.

Definition FreeGroup (A: Type) `{Group A} := option (NonEmptyFreeGroup A).

Print reflect.

Fixpoint to_uniq' {A: Type} `{Group A} (b : bool) (v: A) (x: CanonFreeGroup A) : NonEmptyFreeGroup A :=
match x with 
| []             => Singl b v
| (b', v') :: x' => if eqb b b' 
                      then Stay (sub v v') (to_uniq' b' v' x')
                      else match eqf_eq (sub v v') zero with
                           | ReflectF _ p => Switch (sub v v') (squash p) (to_uniq' b' v' x')
                           | _  => (Singl b v) (* invalid *)
                           end
end.

Definition to_uniq {A: Type} `{Group A} (x: CanonFreeGroup A) : FreeGroup A :=
match x with
| [] => None
| (b, v) :: x' => Some (to_uniq' b v x')
end.

Fixpoint to_canon' {A: Type} `{Group A} (x: NonEmptyFreeGroup A) : CanonFreeGroup A :=
  match x with 
  | Singl b v     => [(b, v)]
  | Stay v x'     => match to_canon' x' with
                     | [] => [(true, v)] (* should not be there *)
                     | (b, v') :: y => (b, op v v') :: (b, v') :: y
                     end
  | Switch v _ x' => match to_canon' x' with
                     | [] => [(true, v)] (* should not be there *)
                     | (b, v') :: y => (negb b, op v v') :: (b, v') :: y
                     end
  end.

Definition to_canon {A: Type} `{Group A} (x: FreeGroup A) : CanonFreeGroup A :=
  match x with
  | None => []
  | Some x' => to_canon' x'
  end.

Lemma op_sub {A: Type} `{Group A} (x y : A) : op (sub x y) y = x.
Proof.
  unfold sub. rewrite op_assoc. rewrite left_inv. rewrite right_id. auto.
Qed.

Lemma sub_op {A: Type} `{Group A} (x y : A) : sub (op x y) y = x.
Proof.
  unfold sub. rewrite op_assoc. rewrite right_inv. rewrite right_id. auto.
Qed.

Lemma squash_not_refl {A : Type} (x: A) (P: Prop) : Squash (x <> x) -> P.
Proof.
  intros H. apply sEmpty_ind. apply (Squash_sind (x <> x)); auto.
  intro H0. exfalso. apply H0. auto.
Qed.

Lemma not_eqb_is_neg (x y : bool) : eqb x y = false -> x = negb y.
Proof.
  intros H. destruct x, y; cbn in *; auto; try inversion H.
Qed.

Lemma some_eq {A: Type} (x y: A) : Some x = Some y -> x = y.
Proof.
  intros H. inversion H. auto.
Qed.

Lemma eqb_not_neg (x y : bool) : eqb x (negb y) = false <-> x = y.
Proof.
  split.
  - intros H. destruct x, y; auto; try inversion H.
  - intros H. subst. destruct y; auto.
Qed.

Lemma group_equation_l_simp {A: Type} `{Group A} (a b c : A) : op a b = op a c -> b = c.
Proof.
  intro H0. assert (op (inv a) (op a b) = op (inv a) (op a c)).
  - rewrite H0. auto.
  - rewrite <- op_assoc, <- op_assoc, left_inv, left_id, left_id in H1. auto.
Qed.

Lemma group_equation_r_simp {A: Type} `{Group A} (a b c : A) : op a c = op b c -> a = b.
Proof.
  intro H0. assert (op (op a c) (inv c) = op (op b c) (inv c)).
  - rewrite H0. auto.
  - rewrite op_assoc, op_assoc, right_inv, right_id, right_id in H1. auto.
Qed.

Lemma sub_inv_uniq {A: Type} `{Group A} (x y: A) : sub x y = zero -> x = y.
Proof.
  unfold sub. rewrite <- (right_inv y). intros H0. 
  apply group_equation_r_simp with (c := inv y). auto.
Qed.

Theorem free_group_epi_canon {A: Type} `{Group A} (x: FreeGroup A) : 
  to_uniq (to_canon x) = x.
Proof.
  destruct x as [x |]; auto. induction x; auto.
  - cbn in *. destruct (to_canon' x0); inversion IHx. destruct p. cbn in *. 
    inversion IHx. subst. rewrite eqb_negb1, sub_op. destruct (eqf_eq x zero); auto.
    subst. apply (squash_not_refl zero); auto.
  - cbn in *. destruct (to_canon' x); inversion IHx. destruct p. cbn in *.
    inversion IHx. subst. rewrite eqb_reflx, sub_op. auto.
Qed.

Theorem canon_epi_free_group {A: Type} `{Group A} (x: CanonFreeGroup A) : 
  Normalized x -> to_canon (to_uniq x) = x.
Proof.
  intros N. induction N; auto. cbn in *. destruct H0 as [v_neq | b_neq].
  - destruct (eqb b b') eqn:b_eq.
    + cbn. rewrite IHN, op_sub. f_equal. f_equal. symmetry. apply eqb_prop. auto.
    + destruct (eqf_eq (sub v v') zero).
      * assert (v = v') by (apply sub_inv_uniq; auto). contradiction.
      * cbn. rewrite IHN, op_sub. f_equal. f_equal. symmetry. apply not_eqb_is_neg. auto.
  - subst. rewrite eqb_reflx. cbn. rewrite IHN, op_sub. auto.
Qed.

Lemma to_canon'_not_nil {A: Type} `{Group A} (x: NonEmptyFreeGroup A) : to_canon' x <> nil.
Proof.
  intros H0. destruct x; cbn in *.
  - inversion H0.
  - destruct (to_canon' x0).
    + inversion H0.
    + destruct p. inversion H0.
  - destruct (to_canon' x).
    + inversion H0.
    + destruct p. inversion H0.
Qed.

Lemma group_add_non_zero {A: Type} `{Group A} (x y : A) : x <> zero -> op x y <> y.
Proof.
  intros H0 H1. apply H0. apply group_equation_r_simp with (c := op y (inv y)).
  rewrite <- op_assoc, H1, right_inv, left_id. auto.
Qed.

Lemma group_squash_non_zero {A: Type} `{Group A} (x : A) : Squash (x <> zero) -> x <> zero.
Proof.
  intros H0. destruct (eqf_eq x zero); auto. subst. apply (squash_not_refl zero). auto.
Qed. 

Theorem free_group_is_normal {A: Type} `{Group A} (x: FreeGroup A) : Normalized (to_canon x).
Proof.
  destruct x as [x |].
  - induction x.
    + cbn. constructor.
    + dependent destruction IHx.
      * assert (to_canon (Some x0) <> []) by (apply to_canon'_not_nil). rewrite x in H0.
        contradiction.
      * cbn in *. rewrite <- x. constructor; constructor. apply group_add_non_zero. 
        apply group_squash_non_zero. auto.
      * cbn in *. rewrite <- x. constructor.
        -- left. apply group_add_non_zero. apply group_squash_non_zero. auto.
        -- constructor; auto.
    + dependent destruction IHx.
      * assert (to_canon (Some x0) <> []) by (apply to_canon'_not_nil). rewrite x in H0.
        contradiction.
      * cbn in *. rewrite <- x. constructor; try right; constructor.
      * cbn in *. rewrite <- x. constructor; try right; constructor; auto.
  - cbn. constructor.
Qed.

Definition option_bind {A B: Type} (x: option A) (f: A -> option B) : option B :=
  match x with
  | None => None
  | Some x' => f x'
  end. 

Fixpoint fg_hd' {A: Type} `{Group A} (x: NonEmptyFreeGroup A) : bool * A :=
  match x with 
  | Singl b v => (b, v)
  | Stay v x' => let (b', v') := fg_hd' x' in (b', op v v')
  | Switch v _ x' => let (b', v') := fg_hd' x' in (negb b', op v v')
  end.

Definition fg_hd {A: Type} `{Group A} (x: FreeGroup A) : option (bool * A) :=
  option_map fg_hd' x.

Theorem fg_hd_for_canon {A: Type} `{Group A} (x: CanonFreeGroup A) :
  Normalized x -> hd_error x = fg_hd (to_uniq x).
Proof.
  intros H0. induction H0; auto. cbn in *. f_equal. inversion IHNormalized. destruct H0.
  - destruct (eqb b b') eqn:e.
    + cbn. rewrite <- H3, op_sub. rewrite eqb_true_iff in e. f_equal; auto.
    + destruct (eqf_eq (sub v v') zero); auto. cbn. rewrite <- H3, op_sub. f_equal.
      apply not_eqb_is_neg. auto.
  - subst. rewrite eqb_reflx. cbn. rewrite <- H3, op_sub. auto.
Qed.

Definition fq_tail' {A: Type} `{Group A} (x: NonEmptyFreeGroup A) : FreeGroup A :=
  match x with 
  | Singl _ _     => None
  | Stay _ x'     => Some x'
  | Switch _ _ x' => Some x'
  end.

Definition fg_tail {A: Type} `{Group A} (x: FreeGroup A) : FreeGroup A :=
  option_bind x fq_tail'.

Definition fg_cons' {A: Type} `{Group A} (b: bool) (v: A) (x: NonEmptyFreeGroup A) : 
   FreeGroup A :=
    let (b', v') := fg_hd' x in 
      if eqb b b'
      then Some (Stay (sub v v') x)
      else match eqf_eq (sub v v') zero with
           | ReflectT _ _ => fq_tail' x
           | ReflectF _ p => Some (Switch (sub v v') (squash p) x)
           end.

Definition fg_cons'2 {A: Type} `{Group A} (p : bool * A) (x: NonEmptyFreeGroup A) :=
  let (b, v) := p in fg_cons' b v x.

Definition fg_cons {A: Type} `{Group A} (b: bool) (v: A) (x: FreeGroup A) : FreeGroup A :=
  match x with
  | None => Some (Singl b v)
  | Some x' => fg_cons' b v x'
  end.

Definition fg_cons2 {A: Type} `{Group A} (p: bool * A) (x: FreeGroup A) : FreeGroup A := 
  let (b, v) := p in fg_cons b v x.
 
Definition elem_inv {A: Type} (x : bool * A) := let (b, v) := x in (negb b, v).

Theorem inv_elem_cons_is_tail {A: Type} `{Group A} (x: NonEmptyFreeGroup A) :
  fg_cons'2 (elem_inv (fg_hd' x)) x = fq_tail' x.
Proof.
  destruct (fg_hd' x) eqn:hd. destruct x; cbn.
  - inversion hd. unfold sub. rewrite eqb_negb1, right_inv.
    destruct (eqf_eq zero zero); auto. contradiction.
  - unfold fg_cons', sub. rewrite hd, eqb_negb1, right_inv. 
    destruct (eqf_eq zero zero); auto. contradiction.
  - unfold fg_cons', sub. rewrite hd, eqb_negb1, right_inv. 
    destruct (eqf_eq zero zero); auto. contradiction.
Qed.

Definition canon_cons {A: Type} `{Group A} (b: bool) (v: A) (x: CanonFreeGroup A) :
  CanonFreeGroup A :=
  match x with
  | [] => [(b, v)]
  | (b', v') :: t => if negb (eqf v v') || eqb b b'
                     then (b, v) :: (b', v') :: t
                     else t
  end.

Fixpoint canon_concat {A: Type} `{Group A} (x y: CanonFreeGroup A) : CanonFreeGroup A :=
  match x with
  | []           => y
  | (b, v) :: x' => canon_cons b v (canon_concat x' y)
  end.

Theorem concat_norm {A: Type} `{Group A} (x y: CanonFreeGroup A) : 
  Normalized x -> Normalized y -> Normalized (canon_concat x y).
Proof.
  intros Nx Ny. induction Nx; auto.
  - cbn. destruct Ny; unfold canon_cons.
    + constructor.
    + destruct (negb (eqf v v0) || eqb b b0 ) eqn:e; constructor.
      * rewrite orb_true_iff, eqb_true_iff, negb_true_iff, eqf_false_iff in e. auto.
      * constructor.
    + destruct (negb (eqf v v0) || eqb b b0) eqn:e; auto. constructor.
      * rewrite orb_true_iff, eqb_true_iff, negb_true_iff, eqf_false_iff in e. auto.
      * constructor; auto.
  - cbn. destruct (canon_concat x y) eqn:c; unfold canon_cons in *.
    + assert (negb (eqf v v') || eqb b b' = true).
      * rewrite orb_true_iff, eqb_true_iff, negb_true_iff, eqf_false_iff. auto.
      * rewrite H1. constructor; auto. constructor.
    + destruct p. cbn in *. rewrite c in IHNx. destruct (negb (eqf v' a) || eqb b' b0) eqn:e.
      * assert (negb (eqf v v') || eqb b b' = true); unfold canon_cons in *.
        -- rewrite orb_true_iff, eqb_true_iff, negb_true_iff, eqf_false_iff. auto.
        -- rewrite H1. rewrite e in IHNx. constructor; auto.
      * cbn in *. destruct c0; try constructor. destruct p.
        destruct (negb (eqf v a0) || eqb b b1) eqn:e1; unfold canon_cons in *; rewrite e in IHNx.
        -- constructor; auto.
           rewrite orb_true_iff, eqb_true_iff, negb_true_iff, eqf_false_iff in e1. auto.
        -- dependent destruction IHNx; auto. constructor.
Qed.

Fixpoint fg_concat' {A: Type} `{Group A} (x: NonEmptyFreeGroup A) 
  (y: FreeGroup A) : FreeGroup A :=
  match x with
  | Singl b v     => fg_cons b v y
  | Stay _ x'     => fg_cons2 (fg_hd' x) (fg_concat' x' y)
  | Switch _ _ x' => fg_cons2 (fg_hd' x) (fg_concat' x' y)
  end.

Definition fg_concat {A: Type} `{Group A} (x y: FreeGroup A) : FreeGroup A :=
  match x with
  | None => y
  | Some x' => fg_concat' x' y
  end.

Lemma eqf_sub_not_zero {A: Type} `{Group A} (x y: A) : sub x y <> zero <-> eqf x y = false.
Proof.
  unfold sub. split.
  - intros H0. destruct (eqf_eq x y); auto. subst. rewrite right_inv in H0. 
    contradiction.
  - intros H0 H1. assert (x = y) by (apply sub_inv_uniq; auto). subst.
    rewrite eqf_refl in H0. discriminate.
Qed.

Theorem free_canon_hd'_izo {A: Type} `{Group A} (x: NonEmptyFreeGroup A) :
  Some (fg_hd' x) = hd_error (to_canon (Some x)).
Proof.
  induction x; auto.
  - cbn in *. destruct (to_canon' x0) eqn:e.
    + exfalso. apply (to_canon'_not_nil x0). auto.
    + destruct p. cbn in *. inversion IHx. rewrite H1. auto.
  - cbn in *. destruct (to_canon' x) eqn:e.
    + exfalso. apply (to_canon'_not_nil x). auto.
    + destruct p. cbn in *. inversion IHx. rewrite H1. auto.
Qed.

Theorem free_canon_hd_izo {A: Type} `{Group A} (x: FreeGroup A) :
  fg_hd x = hd_error (to_canon x).
Proof.
  destruct x as [x |]; auto. cbn. apply free_canon_hd'_izo.
Qed.

Theorem free_canon_cons_izo {A: Type} `{Group A} (b: bool) (v: A) (x: FreeGroup A) :
  to_canon (fg_cons b v x) = canon_cons b v (to_canon x).
Proof.
  destruct x as [x |]; auto. unfold canon_cons. destruct x.
  - cbn. destruct (eqb b b0) eqn:e.
    + cbn. rewrite orb_true_r, op_sub. rewrite eqb_true_iff in e. subst. auto.
    + destruct (eqf_eq (sub v a) zero).
      * assert (v = a) by (apply sub_inv_uniq; auto). subst.
        rewrite eqf_refl. cbn. auto.
      * cbn. rewrite eqf_sub_not_zero in n. rewrite n, op_sub. cbn.
        assert (negb b0 = b) by (symmetry; apply not_eqb_is_neg; auto). 
        subst. auto.
  - cbn. destruct (to_canon' x0) eqn:c.
    + exfalso. apply (to_canon'_not_nil x0). auto.
    + destruct p. unfold fg_cons'. cbn. assert (hd_eq : fg_hd' x0 = (b0, a)).
      { apply some_eq. rewrite free_canon_hd'_izo. cbn. rewrite c. auto. }
      rewrite hd_eq. destruct (eqb b (negb b0)) eqn:eb.
      * cbn. rewrite orb_true_r, c, op_sub. rewrite eqb_true_iff in eb. subst.
        auto.
      * destruct (eqf_eq (sub v (op x a))).
        -- assert (v = (op x a)) by (apply sub_inv_uniq; auto). subst.
          rewrite eqf_refl. cbn. auto.
        -- cbn. rewrite eqf_sub_not_zero in n. rewrite n, c. unfold sub. cbn.
           rewrite (op_assoc  v (inv (op x a))), left_inv, right_id, negb_involutive.
           f_equal. rewrite eqb_not_neg in eb. subst. auto.
  - cbn. destruct (to_canon' x) eqn:c.
    + exfalso. apply (to_canon'_not_nil x). auto.
    + destruct p. unfold fg_cons'. cbn. assert (hd_eq : fg_hd' x = (b0, a0)).
      { apply some_eq. rewrite free_canon_hd'_izo. cbn. rewrite c. auto. }
      rewrite hd_eq. destruct (eqb b b0) eqn:eb.
      * cbn. rewrite orb_true_r, c, op_sub. rewrite eqb_true_iff in eb. subst.
        auto.
      * destruct (eqf_eq (sub v (op a a0))).
        -- assert (v = (op a a0)) by (apply sub_inv_uniq; auto). subst.
          rewrite eqf_refl. cbn. auto.
        -- cbn. rewrite eqf_sub_not_zero in n. rewrite n, c. unfold sub. cbn.
           rewrite (op_assoc  v (inv (op a a0))), left_inv, right_id.
           f_equal. assert (b = negb b0) by (apply not_eqb_is_neg; auto).
           subst. auto.
Qed.

Theorem free_canon_concat_izo {A: Type} `{Group A} (x y: FreeGroup A) :
  to_canon (fg_concat x y) = canon_concat (to_canon x) (to_canon y).
Proof.
  destruct x as [x |]; auto. cbn. induction x.
  - cbn. apply free_canon_cons_izo.
  - cbn. destruct (to_canon' x0) eqn:c.
    + exfalso. apply (to_canon'_not_nil x0). auto.
    + destruct p. assert (hd_eq : fg_hd' x0 = (b, a)).
      { apply some_eq. rewrite free_canon_hd'_izo. cbn. rewrite c. auto. }
      rewrite hd_eq. cbn in *. rewrite <- IHx. apply free_canon_cons_izo.
  - cbn. destruct (to_canon' x) eqn:c.
    + exfalso. apply (to_canon'_not_nil x). auto.
    + destruct p. assert (hd_eq : fg_hd' x = (b, a0)).
      { apply some_eq. rewrite free_canon_hd'_izo. cbn. rewrite c. auto. }
      rewrite hd_eq. cbn in *. rewrite <- IHx. apply free_canon_cons_izo.
Qed.

Fixpoint canon_apinv {A: Type} `{Group A} (x y: CanonFreeGroup A) :=
  match x with
  | [] => y
  | (b, v) :: x' => canon_apinv x' (cons (negb b, v) y)
  end.

Definition canon_inv {A: Type} `{Group A} (x: CanonFreeGroup A) := canon_apinv x [].

Fixpoint canon_append {A: Type} `{Group A} (b: bool) (v: A) (x: CanonFreeGroup A) :=
  match x with
  | [] => [(b, v)]
  | [(b', v')] => if negb (eqf v v') || eqb b b'
                     then [(b', v'); (b, v)]
                     else []
  | h :: x' => h :: (canon_append b v x')
  end.

Theorem group_inv_inv {A: Type} `{Group A} (x: A) : inv (inv x) = x.
Proof.
  rewrite <- (right_id (inv (inv x))), <- (left_inv x), <- (op_assoc), left_inv, left_id.
  auto.
Qed.

Lemma eqb_sym (x y : bool) : eqb x y = eqb y x.
Proof.
  destruct x, y; auto.
Qed.

Lemma eqb_both_neg (x: bool) : eqb (negb x) (negb x) = true.
Proof.
  destruct x; auto.
Qed.

Lemma eqb_false_chain (x y z: bool) : eqb x y = false -> eqb y z = false -> x = z.
Proof.
  intros H H0. destruct x, y, z; auto; cbn in *; discriminate.
Qed.

Lemma condition_iff {A: Type} `{Group A} (b b': bool) (v v': A) :
  v <> v' \/ b = b' <-> negb (eqf v v') || eqb b b' = true.
Proof.
  split.
  - intros [|].
    + rewrite <- eqf_false_iff in H0. rewrite H0. auto.
    + subst. rewrite eqb_reflx, orb_true_r. auto.
  - intro H0. rewrite orb_true_iff, negb_true_iff in H0. destruct H0.
    + left. rewrite <- eqf_false_iff. auto.
    + right. apply eqb_prop. auto.
Qed.

Lemma condition_false_iff {A: Type} `{Group A} (b b': bool) (v v': A) :
  v = v' /\ b = negb b' <-> negb (eqf v v') || eqb b b' = false.
Proof.
  split.
  - intros []. subst. rewrite eqf_refl, eqb_negb1. auto.
  - intro H0. rewrite orb_false_iff, negb_false_iff in H0. destruct H0. split.
    + rewrite <- eqf_true_iff. auto.
    + destruct b, b'; auto; cbn in *; try discriminate.
Qed.

Lemma append_for_normalized {A: Type} `{Group A} (b: bool) (v: A) (x : CanonFreeGroup A) : 
  Normalized (x ++ [(b, v)]) -> x ++ [(b, v)] = canon_append b v x.
Proof.
  revert b v. induction x; auto; intros b v H0; destruct a. cbn in *.
  destruct x.
  - cbn in *. dependent destruction H0. destruct H0.
    + rewrite <- eqf_false_iff in H0. rewrite eqf_sym, H0. auto.
    + subst. rewrite eqb_reflx, orb_true_r. auto.
  - rewrite IHx; auto. dependent destruction H0; auto.
Qed.

Lemma cons_for_normalized {A: Type} `{Group A} (b: bool) (v: A) (x : CanonFreeGroup A) : 
  Normalized ((b, v) :: x) -> (b, v) :: x = canon_cons b v x.
Proof.
  intros Nx. destruct x as [| (b' & v')]; auto. cbn. dependent destruction Nx.
  rewrite condition_iff in H0. rewrite H0. auto.
Qed.

Lemma canon_cons_inv_elem {A: Type} `{Group A} (b b': bool) (v v': A) (x: CanonFreeGroup A) :
  Normalized x -> negb (eqf v v') || eqb b b' = false -> canon_cons b v (canon_cons b' v' x) = x.
Proof.
  intros Nx H0. induction Nx as [| b'' v'' | b'' b''' v'' v'''].
  - cbn. rewrite H0. auto.
  - cbn. destruct (negb (eqf v' v'') || eqb b' b'') eqn:H1.
    + cbn. rewrite H0. auto.
    + cbn. rewrite orb_false_iff, negb_false_iff in H0, H1. destruct H0, H1.
      rewrite eqf_true_iff in H0. rewrite eqf_true_iff in H1. subst. f_equal. f_equal.
      apply eqb_false_chain with (y := b'); auto.
  - rewrite condition_iff in H1. cbn. destruct (negb (eqf v' v'') || eqb b' b'') eqn:H2.
    + cbn. rewrite H0. auto.
    + cbn in *. rewrite <- condition_false_iff in H0, H2.
      destruct H0, H2. subst. rewrite negb_involutive, H1. auto.
Qed.

Lemma normalized_without_head {A: Type} `{Group A} (b: bool) (v: A) (x: CanonFreeGroup A) :
  Normalized ((b, v) :: x) -> Normalized x.
Proof.
  intros Nx. destruct x.
  - constructor.
  - destruct p as (b', v'). dependent destruction Nx. auto.
Qed.

Lemma canon_concat_cons {A: Type} `{Group A} (b: bool) (v: A) (x y: CanonFreeGroup A) :
  Normalized x -> Normalized y -> canon_concat (canon_cons b v x) y  = canon_cons b v (canon_concat x y).
Proof.
  intros Nx Ny. destruct x as [| (b' & v') x']; auto. cbn. 
  destruct (negb (eqf v v') || eqb b b') eqn:e; auto. symmetry.
  apply canon_cons_inv_elem; auto. apply concat_norm; auto. 
  apply (normalized_without_head b' v'). auto.
Qed.

Theorem canon_concat_assoc {A: Type} `{Group A} (x y z: CanonFreeGroup A) : Normalized x -> 
   Normalized y -> Normalized z -> canon_concat (canon_concat x y) z = canon_concat x (canon_concat y z).
Proof.
  revert y z. induction x; intros y z Nx Ny Nz; auto. cbn. destruct a. 
  rewrite canon_concat_cons, IHx; auto.
  - apply (normalized_without_head b a). auto.
  - apply concat_norm; auto. apply (normalized_without_head b a). auto.
Qed.

Lemma normalized_head {A: Type} `{Group A} (b: bool) (v: A) (x: CanonFreeGroup A) :
  hd_error x = None \/ (exists (b' : bool) (v' : A), hd_error x = Some (b', v') /\ (v <> v' \/ b = b'))
   -> Normalized x -> Normalized ((b, v) :: x).
Proof.
  intros H0 Nx. destruct x as [| (b'' & v'')].
  - constructor.
  - constructor; auto. destruct H0.
    + cbn in H0. inversion H0.
    + cbn in H0. destruct H0 as [b' (v' & (H0 & H1))]. inversion H0. subst. auto.
Qed.
  

Lemma noramlized_singl_append {A: Type} `{Group A} (b0 b1 b': bool) (v0 v1 v': A) (x: CanonFreeGroup A) :
  Normalized ((b0, v0) :: (b1, v1) :: x) -> canon_concat ((b0, v0) :: (b1, v1) :: x) [(b', v')] 
  = (b0, v0) :: canon_concat ((b1, v1) :: x) [(b', v')].
Proof.
  revert b0 b1 v0 v1. induction x as [| (b2 & v2)]; intros b0 b1 v0 v1 Nx. 
  - cbn. dependent destruction Nx. destruct ( negb (eqf v1 v') || eqb b1 b') eqn:e; auto.
    cbn. rewrite condition_iff in H0. rewrite H0. auto.
  - cbn in *. dependent destruction Nx. rewrite IHx; auto. rewrite condition_iff in H0.
    cbn. rewrite H0. auto.
Qed.

Lemma append_is_concat_at_end {A: Type} `{Group A} (b: bool) (v: A) (x: CanonFreeGroup A) :
  Normalized x -> canon_append b v x = canon_concat x [(b, v)].
Proof.
  intros Nx. revert b v. induction Nx as [| b' v' | b' b'' v' v'']; auto; intros b v.
  - cbn. rewrite eqf_sym, eqb_sym. auto.
  - rewrite noramlized_singl_append. 
    + cbn in *. rewrite IHNx; auto.
    + constructor; auto.
Qed.

Lemma cons_is_concat_at_start {A: Type} `{Group A} (b: bool) (v: A) (x: CanonFreeGroup A) :
  canon_cons b v x = canon_concat [(b, v)] x.
Proof.
  cbn. auto.
Qed.

Theorem cons_append_comm {A: Type} `{Group A} (b b': bool) (v v': A) (x: CanonFreeGroup A) :
  Normalized x -> canon_cons b v (canon_append b' v' x) = canon_append b' v' (canon_cons b v x).
Proof.
  intros Nx. rewrite cons_is_concat_at_start, cons_is_concat_at_start, 
  append_is_concat_at_end, append_is_concat_at_end, canon_concat_assoc; auto.
  - constructor.
  - constructor.
  - apply concat_norm; auto; try constructor.
Qed.

Theorem canon_concat_append {A: Type} `{Group A} (b: bool) (v: A) (x y: CanonFreeGroup A) :
  Normalized x -> Normalized y -> 
  canon_concat x (canon_append b v y) = canon_append b v (canon_concat x y).
Proof.
  induction x; auto. intros Nx Ny. cbn. destruct a. rewrite IHx; auto. apply cons_append_comm.
  - apply concat_norm; auto. apply (normalized_without_head b0 a); auto.
  - apply (normalized_without_head b0 a); auto.
Qed.

Lemma appinv_list_remaining {A: Type} `{Group A} (x y: CanonFreeGroup A) :
  canon_concat x (canon_apinv x y) = y.
Proof.
  revert y. induction x; auto. intros y. cbn. destruct a. rewrite IHx.
  cbn. rewrite eqf_refl, eqb_negb2. cbn. auto.
Qed.

Theorem canon_right_inv {A: Type} `{Group A} (x : CanonFreeGroup A) : 
  canon_concat x (canon_inv x) = [].
Proof.
  induction x; auto. cbn. destruct a. rewrite appinv_list_remaining.
  cbn. rewrite eqf_refl, eqb_negb2. cbn. auto.
Qed.

Lemma cannon_inv_concat {A: Type} `{Group A} (x y: CanonFreeGroup A) : 
  canon_apinv x y = canon_inv x ++ y.
Proof.
  unfold canon_inv. revert y. induction x; auto; intros y.
  cbn. destruct a. rewrite IHx, (IHx [(negb b, a)]), <- app_assoc.
  auto.
Qed.

Lemma cannon_inv_append {A: Type} `{Group A} (b: bool) (v: A) (x : CanonFreeGroup A) : 
  canon_inv (x ++ [(b, v)]) = (negb b, v) :: canon_inv x.
Proof.
  revert b v. induction x; auto. intros b v. cbn. destruct a.
  rewrite cannon_inv_concat, IHx, cannon_inv_concat, app_comm_cons. auto.
Qed.

Lemma concat_normalized_l {A: Type} `{Group A} (x y: CanonFreeGroup A) :
  Normalized (x ++ y) -> Normalized x.
Proof.
  destruct x as [| (b, v)].
  - constructor.
  - revert b v. induction x as [| (b', v')]; intros b v H0.
    + constructor.
    + dependent destruction H0. constructor; auto.
Qed.

Lemma concat_normalized_r {A: Type} `{Group A} (x y: CanonFreeGroup A) :
  Normalized (x ++ y) -> Normalized y.
Proof.
  revert y. induction x as [| (b, v)]; intros y.
  - cbn. auto.
  - intros H0. apply IHx. rewrite <- app_comm_cons in H0.
    apply (normalized_without_head b v). auto.
Qed.

Lemma normalized_list_concat {A: Type} `{Group A} (b b': bool) (v v': A) (x y: CanonFreeGroup A) :
  Normalized (x ++ [(b, v)]) -> Normalized ((b', v') :: y) ->
  v <> v' \/ b = b' -> Normalized (x ++ (b, v) :: (b', v') :: y).
Proof.
  revert b b' v v' y. induction x using rev_ind; intros b b' v v' y Nx Ny H0.
  - cbn. constructor; auto.
  - rewrite <- app_assoc. cbn. destruct x as (b'', v''). apply IHx.
    + apply (concat_normalized_l (x0 ++ [(b'', v'')]) [(b, v)]). auto.
    + constructor; auto.
    + assert (Normalized [(b'', v''); (b, v)]).
      { apply (concat_normalized_r x0). rewrite <- app_assoc in Nx. auto. }
      dependent destruction H1. auto.
Qed. 

Theorem rev_normalized {A: Type} `{Group A} (b b': bool) (v v': A) (x: CanonFreeGroup A) :
  Normalized (x ++ [(b, v)]) -> v <> v' \/ b = b' -> Normalized (x ++ [(b, v); (b', v')]).
Proof.
  revert b b' v v'. destruct x as [| (b'', v'')] using rev_ind ; intros b b' v v' Nx H0.
  - cbn. constructor; auto. constructor.
  - apply normalized_list_concat; auto. constructor.
Qed. 

Theorem inv_norm {A: Type} `{Group A} (x: CanonFreeGroup A) : 
  Normalized x -> Normalized (canon_inv x).
Proof.
  intros Nx. induction Nx.
  - cbn. constructor.
  - cbn. constructor.
  - cbn in *. rewrite cannon_inv_concat in IHNx. rewrite cannon_inv_concat.
    apply rev_normalized; auto. destruct H0; auto. subst. auto.
Qed.

Theorem canon_left_inv {A: Type} `{Group A} (x : CanonFreeGroup A) : 
  Normalized x -> canon_concat (canon_inv x) x = [].
Proof.
  induction x using rev_ind; auto. intros N. destruct x.
  rewrite cannon_inv_append. cbn. rewrite append_for_normalized; auto.
  assert (Normalized x0). { apply (concat_normalized_l x0 [(b, a)]). auto. }
  rewrite canon_concat_append, IHx; auto.
  - cbn. rewrite eqf_refl, eqb_negb1. auto.
  - apply inv_norm; auto.
Qed.

Theorem canon_left_id {A: Type} `{Group A} (x : CanonFreeGroup A) : 
  canon_concat [] x = x.
Proof.
  auto.
Qed.

Theorem canon_right_id {A: Type} `{Group A} (x : CanonFreeGroup A) : 
  Normalized x -> canon_concat x [] = x.
Proof.
  intros Nx. induction x as [| (b, v)]; auto. cbn. rewrite IHx, cons_for_normalized; auto.
  apply (normalized_without_head b v); auto.
Qed.

(* Free Group eqdec *)

Fixpoint fg_eq' {A: Type} `{Group A} (x y: NonEmptyFreeGroup A) : bool :=
  match x, y with
  | Singl xb xv,    Singl yb yv    => eqb xb yb && eqf xv yv
  | Switch xr _ x', Switch yr _ y' => eqf xr yr && fg_eq' x' y'
  | Stay xr x',     Stay yr y'     => eqf xr yr && fg_eq' x' y'
  | _,              _              => false
  end.

Definition fg_eq {A: Type} `{Group A} (x y: FreeGroup A) : bool :=
  match x, y with
  | None,    None    => true
  | Some x', Some y' => fg_eq' x' y'
  | _,       _       => false
  end.

Theorem fq_eqf_eq {A: Type} `{Group A} (x y: FreeGroup A) : reflect (x = y) (fg_eq x y).
Proof.
  apply iff_reflect. split.
  - intros []. destruct x as [x |]; auto. induction x.
    + cbn. rewrite eqb_reflx, eqf_refl. auto.
    + cbn in *. rewrite eqf_refl, IHx. auto.
    + cbn in *. rewrite eqf_refl, IHx. auto.
  - intros H0. destruct x as [x |]; destruct y as [y |]; cbn in *; try inversion H0; auto.
    f_equal. revert H0 H2. intros _. revert y. induction x; intros y H0.
    + destruct y; cbn in *; try inversion H0. rewrite andb_true_iff in H0.
      destruct H0. rewrite eqb_true_iff in H0. rewrite eqf_true_iff in H1. 
      subst. auto.
    + destruct y; cbn in *; inversion H0. rewrite andb_true_iff in H0.
      destruct H0. rewrite eqf_true_iff in H0. rewrite andb_true_iff in H2.
      destruct H2. specialize (IHx y H1). subst. auto.
    + destruct y; cbn in *; inversion H0. rewrite andb_true_iff in H0.
      destruct H0. rewrite eqf_true_iff in H0. subst. f_equal. apply IHx.
      rewrite andb_true_iff in H2. destruct H2. auto.
Qed.

Definition fg_canon_concat {A: Type} `{Group A} (x y: FreeGroup A) : FreeGroup A :=
  to_uniq (canon_concat (to_canon x) (to_canon y)).

Definition fg_canon_inv {A: Type} `{Group A} (x: FreeGroup A) : FreeGroup A :=
  to_uniq (canon_inv (to_canon x)).


(* Free Group is Group *)
Definition fg_zero {A: Type} `{Group A} := None (A := NonEmptyFreeGroup A).

Theorem fq_left_inv {A: Type} `{Group A} (x y: FreeGroup A) : 
  fg_canon_concat (fg_canon_inv x) x = fg_zero.
Proof.
  unfold fg_canon_concat, fg_canon_inv. rewrite canon_epi_free_group.
  - rewrite canon_left_inv; auto. apply free_group_is_normal.
  - apply inv_norm. apply free_group_is_normal.
Qed.

Theorem fq_right_inv {A: Type} `{Group A} (x y: FreeGroup A) : 
  fg_canon_concat x (fg_canon_inv x) = fg_zero.
Proof.
  unfold fg_canon_concat, fg_canon_inv. rewrite canon_epi_free_group.
  - rewrite canon_right_inv; auto.
  - apply inv_norm. apply free_group_is_normal.
Qed.

Theorem fq_left_id {A: Type} `{Group A} (x y: FreeGroup A) : 
  fg_canon_concat fg_zero x = x.
Proof.
  unfold fg_canon_concat, fg_canon_inv. cbn. apply free_group_epi_canon.
Qed.

Theorem fq_right_id {A: Type} `{Group A} (x y: FreeGroup A) : 
  fg_canon_concat x fg_zero = x.
Proof.
  unfold fg_canon_concat, fg_canon_inv. cbn. rewrite canon_right_id.
  - apply free_group_epi_canon.
  - apply free_group_is_normal.
Qed.

Theorem fq_op_assoc {A: Type} `{Group A} (x y z: FreeGroup A) : 
  fg_canon_concat (fg_canon_concat x y) z = fg_canon_concat x (fg_canon_concat y z).
Proof.
  unfold fg_canon_concat, fg_canon_inv. rewrite canon_epi_free_group, canon_epi_free_group.
  - rewrite canon_concat_assoc; auto; try apply free_group_is_normal.
  - apply concat_norm; apply free_group_is_normal.
  - apply concat_norm; apply free_group_is_normal.
Qed.

Global Program Instance FreeGroup_is_Group {A: Type} `{Group A} : Group (FreeGroup A) := {
  zero      := fg_zero;
  op        := fg_canon_concat;
  inv       := fg_canon_inv;
  eqf       := fg_eq;
}.

Next Obligation. apply fq_left_id; auto. Defined.
Next Obligation. apply fq_right_id; auto. Defined.
Next Obligation. apply fq_left_inv; auto. Defined.
Next Obligation. apply fq_right_inv; auto. Defined.
Next Obligation. apply fq_op_assoc; auto. Defined.
Next Obligation. apply fq_eqf_eq; auto. Defined.



(* Suspicous Integrals *)
Global Program Instance Unit_is_Group : Group unit := {
  zero      := tt;
  op        := fun _ _ => tt;
  inv       := fun _ => tt;
  eqf       := fun _ _ => true;
}.

Next Obligation. destruct x; auto. Defined.
Next Obligation. destruct x; auto. Defined.
Next Obligation. constructor. destruct x, y. auto. Defined.

Definition Integrals := FreeGroup unit.

Class Monad (M : Type -> Type) := MondadDef {
  pure       : forall {A : Type}, A -> M A;
  bind       : forall {A B : Type}, M A -> (A -> M B) -> M B;
  left_bind  : forall {A B : Type} (f: A -> M B) (x: A), bind (pure x) f = f x; 
  right_bind : forall {A B : Type} (x: M A), bind x pure = x; 
  comp_bind  : forall {A B C : Type} (f: B -> M C) (g : A -> M B) (x: M A),
                 bind (bind x g) f = bind x (fun y => bind (g y) f);
}.

Definition fg_pure {A: Type} `{Group A} (x: A) := Singl true x.

Definition canon_pure {A: Type} `{Group A} (x: A) := [(true, x)].

Fixpoint canon_bind {A B: Type} `{Group A} `{Group B} (x : CanonFreeGroup A)
  (f: A -> CanonFreeGroup B) : CanonFreeGroup B :=
  match x with
  | [] => []
  | (b, v) :: x' => if b
                    then canon_concat (f v) (canon_bind x' f)
                    else canon_concat (canon_inv (f v)) (canon_bind x' f)
  end.

Definition fg_bind {A B: Type} `{Group A} `{Group B} (x : FreeGroup A)
  (f: A -> FreeGroup B) : FreeGroup B :=
  to_uniq (canon_bind (to_canon x) (fun y => to_canon (f y))).

Theorem bind_norm {A B: Type} `{Group A} `{Group B} (x: CanonFreeGroup A)
  (f: A -> CanonFreeGroup B) : (forall a: A, Normalized (f a)) -> Normalized (canon_bind x f).
Proof.
  intros Nf. induction x as [|(b, v)].
  - cbn. constructor.
  - cbn. destruct b.
    + apply concat_norm; auto.
    + apply concat_norm; try apply inv_norm; auto.
Qed.

Theorem canon_bind_cons {A B: Type} `{Group A} `{Group B} (b: bool) (v: A) 
  (x: CanonFreeGroup A) (f: A -> CanonFreeGroup B) :
  (forall a: A, Normalized (f a)) -> canon_bind (canon_cons b v x) f = 
  canon_concat (if b then f v else canon_inv (f v)) (canon_bind x f).
Proof.
  intros Nf. destruct x as [| (b', v')].
  - cbn. destruct b; auto.
  - cbn. destruct b, b'.
    + rewrite eqb_reflx, orb_true_r. auto.
    + destruct (eqf v v') eqn:veq; auto. rewrite eqf_true_iff in veq. subst. 
      cbn. rewrite <- canon_concat_assoc, canon_right_inv; auto.
      * apply inv_norm. auto.
      * apply bind_norm; auto.
    + destruct (eqf v v') eqn:veq; auto. rewrite eqf_true_iff in veq. subst. 
      cbn. rewrite <- canon_concat_assoc, canon_left_inv; auto.
      * apply inv_norm. auto.
      * apply bind_norm; auto.
    + rewrite eqb_reflx, orb_true_r. auto.
Qed.

Theorem canon_bind_concat {A B: Type} `{Group A} `{Group B} (x y : CanonFreeGroup A)
  (f: A -> CanonFreeGroup B) : (forall a: A, Normalized (f a)) ->
  canon_bind (canon_concat x y) f = canon_concat (canon_bind x f) (canon_bind y f).
Proof.
  intros Nf. induction x as [| (b, v)]; auto. cbn. rewrite canon_bind_cons; auto.
  destruct b.
  - rewrite IHx, canon_concat_assoc; try apply bind_norm;auto.
  - rewrite IHx, canon_concat_assoc; try apply bind_norm; try apply inv_norm; auto.
Qed.

Lemma concat_for_normalized {A: Type} `{Group A} (x y: CanonFreeGroup A) :
  Normalized (x ++ y) -> canon_concat x y = x ++ y.
Proof.
  intro N. induction x as [| (b, v)]; auto. cbn. 
  rewrite IHx, cons_for_normalized; auto. apply (normalized_without_head b v). 
  rewrite app_comm_cons. auto. 
Qed.

Lemma eqb_neg_izo (x y : bool) : eqb (negb x) (negb y) = eqb x y.
Proof.
  destruct x, y; auto.
Qed.

Lemma cons_inv_is_append {A: Type} `{Group A} (b: bool) (v : A) (x: CanonFreeGroup A) :
  Normalized x -> canon_inv (canon_cons b v x) = canon_append (negb b) v (canon_inv x).
Proof.
  intros Nx. induction x as [| (b', v')]; auto. cbn.
  destruct (negb (eqf v v') || eqb b b') eqn:e.
  - cbn. assert (Normalized (canon_inv ((b', v') :: x))) by (apply inv_norm; auto).
    rewrite cannon_inv_concat, cannon_inv_concat, append_is_concat_at_end, 
    concat_for_normalized, <- app_assoc; auto.
    + rewrite <- app_assoc. cbn. apply rev_normalized.
      * rewrite <- cannon_inv_concat. auto.
      * rewrite condition_iff, eqf_sym, eqb_sym, eqb_neg_izo. auto.
    + rewrite <- cannon_inv_concat. auto.
  - assert (Normalized (canon_inv ((b', v') :: x))) by (apply inv_norm; auto).
    rewrite cannon_inv_concat,  cannon_inv_concat, append_is_concat_at_end, 
    <- (concat_for_normalized (canon_inv x) [(negb b', v')]), canon_concat_assoc;
    auto; try constructor.
    + cbn. rewrite eqf_sym, eqb_sym, eqb_neg_izo, e, canon_right_id, app_nil_r; auto.
      apply inv_norm. apply (normalized_without_head b' v'). auto.
    + apply inv_norm. apply (normalized_without_head b' v'). auto.
    + rewrite <- cannon_inv_concat. auto.
    + rewrite <- cannon_inv_concat. auto.
Qed.

Lemma cons_apinv_is_append {A: Type} `{Group A} (b: bool) (v : A) (x: CanonFreeGroup A) :
  Normalized x -> canon_apinv (canon_cons b v x) [] = canon_append (negb b) v (canon_apinv x []).
Proof.
  intros Nx. apply cons_inv_is_append. auto.
Qed. 

Lemma canon_concat_inv {A: Type} `{Group A} (x y: CanonFreeGroup A) :
  Normalized x -> Normalized y -> 
  canon_inv (canon_concat x y) = canon_concat (canon_inv y) (canon_inv x). 
Proof.
  unfold canon_inv. intros Nx Ny. induction x as [| (b, v)].
  - cbn. rewrite canon_right_id; auto. apply inv_norm; auto.
  - cbn. assert (Normalized x) by (apply (normalized_without_head b v); auto).
    assert (Normalized (canon_inv ((b, v) :: x))) by (apply inv_norm; auto).
    rewrite cons_apinv_is_append, IHx, (cannon_inv_concat x [(negb b, v)]), 
    <- concat_for_normalized, append_is_concat_at_end, canon_concat_assoc; auto; 
    try constructor; try apply inv_norm; auto.
    + apply concat_norm;  apply inv_norm; auto. 
    + rewrite <- cannon_inv_concat. auto.
    + apply concat_norm; auto.
Qed.

Lemma canon_concat_apinv {A: Type} `{Group A} (x y: CanonFreeGroup A) :
  Normalized x -> Normalized y -> 
  canon_apinv (canon_concat x y) [] = canon_concat (canon_apinv y []) (canon_apinv x []).
Proof. 
  intros Hx Hy. apply canon_concat_inv; auto.
Qed.

Lemma canon_bind_rev {A B: Type} `{Group A} `{Group B} (b: bool) (v: A)
  (x: CanonFreeGroup A) (f: A -> CanonFreeGroup B) : (forall a: A, Normalized (f a)) -> 
  (canon_bind (x ++ [(b, v)]) f) = canon_concat (canon_bind x f) (if b then f v else canon_inv (f v)).
Proof.
  intros Nf. induction x as [| (b', v')]; auto.
  - cbn. destruct b; rewrite canon_right_id; auto. apply inv_norm. auto.
  - cbn. destruct b, b'.
    + rewrite canon_concat_assoc, IHx; try apply bind_norm; auto.
    + rewrite canon_concat_assoc, IHx; try apply bind_norm; try apply inv_norm; auto.
    + rewrite canon_concat_assoc, IHx; try apply bind_norm; try apply inv_norm; auto.
    + rewrite canon_concat_assoc, IHx; try apply bind_norm; try apply inv_norm; auto.
Qed.

Lemma concat_inv_inv {A: Type} `{Group A} (x : CanonFreeGroup A) : 
  Normalized x -> canon_inv (canon_inv x) = x.
Proof.
  intro Nx. rewrite <- (canon_right_id (canon_inv (canon_inv x))), <- (canon_left_inv x),
  <- (canon_concat_assoc), canon_left_inv; try apply inv_norm; try apply inv_norm; auto.
Qed.

Lemma concat_apinv_apinv {A: Type} `{Group A} (x : CanonFreeGroup A) : 
  Normalized x -> canon_apinv (canon_apinv x []) [] = x.
Proof.
  intro Nx. apply concat_inv_inv. auto.
Qed.

Theorem canon_bind_inv {A B: Type} `{Group A} `{Group B} (x: CanonFreeGroup A)
  (f: A -> CanonFreeGroup B) : (forall a: A, Normalized (f a)) -> 
  canon_inv (canon_bind x f) = (canon_bind (canon_inv x) f).
Proof.
  unfold canon_inv. intros Nf. induction x as [| (b, v)]; auto. cbn. destruct b.
  - cbn. rewrite canon_concat_apinv, IHx, (cannon_inv_concat x [(false, v)]), canon_bind_rev;
    try apply bind_norm; auto.
  - cbn. rewrite canon_concat_apinv, IHx, (cannon_inv_concat x [(true, v)]), canon_bind_rev;
    try apply bind_norm; try apply inv_norm; auto. unfold canon_inv.
    rewrite concat_apinv_apinv; auto. 
Qed. 



Theorem canon_comp_bind {A B C : Type} `{Group A} `{Group B} `{Group C}
  (f: B -> CanonFreeGroup C) (g : A -> CanonFreeGroup B) (x: CanonFreeGroup A) : 
  (forall b: B, Normalized (f b)) -> (forall a: A, Normalized (g a)) ->
  canon_bind (canon_bind x g) f = canon_bind x (fun y => canon_bind (g y) f).
Proof.
  intros Nf Ng. induction x as [|(b, v) x]; auto. cbn. destruct b.
  - rewrite canon_bind_concat, IHx; auto.
  - rewrite canon_bind_concat, IHx, <- canon_bind_inv; auto.
Qed.

Theorem canon_left_bind {A B : Type} `{Group A} `{Group B} (f : A -> CanonFreeGroup B)
  (x: A) : (forall a: A, Normalized (f a)) -> canon_bind (canon_pure x) f = f x.
Proof.
  intro Nf. cbn. rewrite canon_right_id; auto.
Qed.

Theorem canon_right_bind {A B : Type} `{Group A} `{Group B} (f : A -> CanonFreeGroup B)
  (x: CanonFreeGroup A) : Normalized x -> canon_bind x canon_pure = x.
Proof.
  intro Nx. induction x as [| (b, v)]; auto. cbn. destruct b.
  - rewrite IHx.
    + symmetry. apply cons_for_normalized. auto.
    + apply (normalized_without_head true v). auto.
  - rewrite IHx.
    + symmetry. apply cons_for_normalized. auto.
    + apply (normalized_without_head false v). auto.
Qed.
  
  





