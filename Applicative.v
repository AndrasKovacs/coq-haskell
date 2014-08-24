Require Export Endo.
Require Export Tuple.

Reserved Notation "f <*> g" (at level 68, left associativity).

Reserved Notation "X ⊗ Y" (at level 67, right associativity).
Reserved Notation "X ● Y" (at level 67, right associativity).

(* Class Monoidal (C : Category) := { *)
(*     product  : C ⟶ [C, C] where "X ⊗ Y" := (product X Y); *)
(*     unit_obj : C *)
(* }. *)

(* Infix "●" := product (at level 67, right associativity). *)

Class Applicative (F : Type -> Type) :=
{ is_functor :> Functor F

; eta : forall {X}, X -> F X
; apply : forall {X Y}, F (X -> Y) -> F X -> F Y
    where "f <*> g" := (apply f g)

; app_identity : forall {X}, apply (eta (@id X)) = id
; app_composition
    : forall {X Y Z} (v : F (X -> Y)) (u : F (Y -> Z)) (w : F X),
    eta compose <*> u <*> v <*> w = u <*> (v <*> w)
; app_homomorphism : forall {X Y} (x : X) (f : X -> Y),
    eta f <*> eta x = eta (f x)
; app_interchange : forall {X Y} (y : X) (u : F (X -> Y)),
    u <*> eta y = eta (fun f => f y) <*> u

; app_fmap_unit : forall {X Y} (f : X -> Y), apply (eta f) = fmap f
}.

Notation "eta/ M" := (@eta M _ _) (at level 68).
Notation "eta/ M N" := (@eta (fun X => M (N X)) _ _) (at level 66).

Notation "apply[ M ]  f" := (@apply M _ _ _ f) (at level 68).
Notation "apply[ M N ]  f" := (@apply (fun X => M (N X)) _ _ _ f) (at level 66).
Notation "apply[ M N O ]  f" := (@apply (fun X => M (N (O X))) _ _ _ f) (at level 64).

Notation "f <*> g" := (apply f g) (at level 68, left associativity).

Notation "[| f x y .. z |]" := (.. (f <$> x <*> y) .. <*> z)
    (at level 9, left associativity, f at level 9,
     x at level 9, y at level 9, z at level 9).

Definition app_merge {X Y Z W} (f : X -> Y) (g : Z -> W)
  (t : X * Z) : Y * W  :=
  match t with (x, z) => (f x, g z) end.

Definition app_prod {F : Type -> Type} `{Applicative F}
  {X Y} (x : F X) (y : F Y) : F (X * Y) := pair <$> x <*> y.

Notation "f *** g" := (app_merge f g) (at level 68, left associativity).

Notation "f ** g" := (app_prod f g) (at level 68, left associativity).

Ltac rewrite_app_homomorphisms :=
  (repeat (rewrite <- app_fmap_unit);
   rewrite app_homomorphism;
   repeat (rewrite app_fmap_unit)).

Section Applicatives.

  Variable F : Type -> Type.
  Context `{Applicative F}.

  Theorem app_fmap_compose : forall A B (f : A -> B),
    eta ∘ f = fmap f ∘ eta.
  Proof.
    intros.
    extensionality x.
    unfold compose.
    rewrite <- app_homomorphism.
    rewrite app_fmap_unit.
    reflexivity.
  Qed.

  Theorem app_fmap_compose_x : forall A B (f : A -> B) (x : A),
    eta (f x) = fmap f (eta x).
  Proof.
    intros.
    assert (eta (f x) = (eta ∘ f) x).
      unfold compose. reflexivity.
    assert (fmap f (eta x) = (fmap f ∘ eta) x).
      unfold compose. reflexivity.
    rewrite H0. rewrite H1.
    rewrite app_fmap_compose.
    reflexivity.
  Qed.

  Theorem app_identity_x : forall {X} {x : F X},
    apply (eta (@id X)) x = id x.
  Proof.
    intros.
    rewrite app_fmap_unit.
    apply fun_identity_x.
  Qed.

  Theorem app_homomorphism_2 : forall {X Y Z} (x : X) (y : Y) (f : X -> Y -> Z),
    f <$> eta x <*> eta y = eta (f x y).
  Proof.
    intros.
    rewrite <- app_homomorphism.
    rewrite <- app_homomorphism.
    rewrite app_fmap_unit.
    reflexivity.
  Qed.

  (* This theorem was given as an exercise by Brent Yorgey at:

     http://www.haskell.org/haskellwiki/Typeclassopedia#Applicative
  *)
  Theorem app_flip : forall {X Y} (x : F X) (f : X -> Y),
    eta f <*> x = eta (flip call) <*> x <*> eta f.
  Proof.
    intros.
    rewrite app_interchange.
    rewrite <- app_composition.
    rewrite app_fmap_unit.
    rewrite app_fmap_unit.
    rewrite app_homomorphism_2.
    unfold compose.
    rewrite app_fmap_unit.
    reflexivity.
  Qed.

  Definition app_unit : F unit := eta tt.

  Theorem app_embed : forall {G : Type -> Type} `{Applicative G}
      {X Y} (x : G (X -> Y)) (y : G X),
    eta (x <*> y) = eta apply <*> eta x <*> eta y.
  Proof.
    intros.
    rewrite_app_homomorphisms.
    rewrite <- app_homomorphism.
    rewrite <- app_fmap_unit.
    reflexivity.
  Qed.

  Theorem app_split : forall A B C (f : A -> B -> C) (x : F A) (y : F B),
    f <$> x <*> y = uncurry f <$> (x ** y).
  Proof.
    intros. unfold app_prod.
    repeat (rewrite <- app_fmap_unit).
    repeat (rewrite <- app_composition; f_equal).
    repeat (rewrite app_homomorphism).
    unfold uncurry, compose. f_equal.
  Qed.

  Theorem app_naturality
    : forall {A B C D} (f : A -> C) (g : B -> D) (u : F A) (v : F B),
    fmap (f *** g) (u ** v) = (fmap f u) ** (fmap g v).
  Proof.
    intros.
    unfold app_prod.
    rewrite <- app_fmap_unit.
    rewrite fun_composition_x.
    repeat (rewrite <- app_fmap_unit).
    rewrite <- app_composition.
    rewrite <- app_composition.
    rewrite <- app_composition.
    rewrite <- app_composition.
    rewrite app_composition.
    rewrite app_composition.
    f_equal.
    rewrite_app_homomorphisms.
    rewrite fun_composition_x.
    rewrite fun_composition_x.
    rewrite app_interchange.
    rewrite app_fmap_unit.
    rewrite fun_composition_x.
    f_equal.
  Qed.

  Theorem app_left_identity : forall {A} (v : F A), (eta tt ** v) ≡ v.
  Proof.
    intros.
    unfold app_prod, app_unit.
    rewrite_app_homomorphisms.
    split.
      assert (fmap (pair tt) =
              (@from (F (unit * A)) (F A)
                     (Functor_Isomorphism _ LTuple_Isomorphism))).
        reflexivity. rewrite H0. clear H0.
      apply iso_from_x.
      reflexivity.
  Qed.

  Theorem app_right_identity : forall {A : Type} (v : F A),
    (v ** eta tt) ≡ v.
  Proof.
    intros.
    unfold app_prod, app_unit.
    rewrite <- app_fmap_unit.
    rewrite app_interchange.
    rewrite <- app_composition.
    rewrite app_homomorphism.
    rewrite app_homomorphism.
    rewrite app_fmap_unit.
    unfold compose.
    split.
      assert (fmap (fun x : A => (x, tt)) =
              (@from (F (A * unit)) (F A)
                     (Functor_Isomorphism _ RTuple_Isomorphism))).
        reflexivity. rewrite H0.
      apply iso_from_x.
      reflexivity.
  Qed.

  Theorem app_embed_left_triple : forall A B C (u : F A) (v : F B) (w : F C),
    u ** v ** w = left_triple <$> u <*> v <*> w.
  Proof.
    intros.
    unfold app_prod.
    repeat (rewrite <- app_fmap_unit).
    rewrite <- app_composition.
    f_equal. f_equal.
    rewrite_app_homomorphisms.
    rewrite fun_composition_x.
    reflexivity.
  Qed.

  Theorem app_embed_right_triple : forall A B C (u : F A) (v : F B) (w : F C),
    u ** (v ** w) = right_triple <$> u <*> v <*> w.
  Proof.
    intros.
    unfold app_prod.
    repeat (rewrite <- app_fmap_unit).
    rewrite <- app_composition.
    f_equal. f_equal.
    repeat (rewrite app_fmap_unit).
    rewrite fun_composition_x.
    repeat (rewrite <- app_fmap_unit).
    rewrite <- app_composition.
    f_equal.
    repeat (rewrite app_fmap_unit).
    rewrite fun_composition_x.
    rewrite app_interchange.
    rewrite app_fmap_unit.
    rewrite fun_composition_x.
    unfold compose.
    reflexivity.
  Qed.

  Theorem app_associativity : forall A B C (u : F A) (v : F B) (w : F C),
    ((u ** v) ** w) ≡ (u ** (v ** w)).
  Proof.
    intros.
    rewrite app_embed_left_triple.
    rewrite app_embed_right_triple.
    split; simpl;
    repeat (rewrite <- app_fmap_unit);
    rewrite <- app_composition;
    rewrite <- app_composition;
    rewrite <- app_composition;
    repeat f_equal;
    repeat (rewrite app_fmap_unit);
    rewrite fun_composition_x;
    rewrite fun_composition_x;
    rewrite <- app_fmap_compose_x;
    rewrite app_homomorphism;
    reflexivity.
  Qed.

  Definition liftA2 {A B C} (f : A -> B -> C) (x : F A) (y : F B) : F C :=
    f <$> x <*> y.

End Applicatives.