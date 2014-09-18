Require Export Monad.
Require Export ACompose.
Require Coq.Setoids.Setoid.

Class Monad_Distributes (M : Type -> Type) (N : Type -> Type)
  `{Monad M} `{Applicative N} :=
{ prod : forall {A : Type}, N (M (N A)) -> M (N A)
; prod_law_1 : forall {A B : Type} (f : A -> B),
    prod ∘ fmap[N] (@fmap (fun X => M (N X)) _ _ _ f) =
    (@fmap (fun X => M (N X)) _ _ _ f) ∘ prod
; prod_law_2 : forall {A : Type}, (@prod A) ∘ pure/N = id
; prod_law_3 : forall {A : Type},
    prod ∘ fmap[N] (@pure (fun X => M (N X)) _ A) = pure/M
; prod_law_4 : forall {A : Type},
    prod ∘ fmap[N] (join/M ∘ fmap[M] prod) =
    join/M ∘ fmap[M] prod ∘ (@prod (M (N A)))
}.

(* These proofs are due to Mark P. Jones and Luc Duponcheel in their article
   "Composing monads", Research Report YALEU/DCS/RR-1004, December 1993.

   Given any Monad M, and any Premonad N (i.e., having pure), and further given
   an operation [prod] and its accompanying four laws, it can be shown that M
   N is closed under composition.
*)
Global Instance Monad_Compose (M : Type -> Type) (N : Type -> Type)
  `{Monad M} `{Applicative N} `{Monad_Distributes M N}
  : Monad (fun X => M (N X)) :=
{ is_applicative := Applicative_Compose M N
; join := fun A => join/M ∘ fmap[M] (@prod M N _ _ _ A)
}.
Proof.
  - (* monad_law_1 *) intros.
    rewrite <- comp_assoc with (f := join/M).
    rewrite <- comp_assoc with (f := join/M).
    rewrite comp_assoc with (f := fmap[M] (@prod M N _ _ _ X)).
    rewrite <- monad_law_4.
    rewrite <- comp_assoc.
    rewrite comp_assoc with (f := join/M).
    rewrite comp_assoc with (f := join/M).
    rewrite <- monad_law_1.
    repeat (rewrite <- comp_assoc).
    repeat (rewrite fun_composition).
    repeat (rewrite comp_assoc).
    rewrite <- prod_law_4.
    repeat (rewrite <- fun_composition).
    unfold compose_fmap. reflexivity.

  - (* monad_law_2 *) intros.
    rewrite <- monad_law_2.
    rewrite <- prod_law_3. simpl.
    repeat (rewrite <- comp_assoc).
    repeat (rewrite <- fun_composition).
    unfold compose_fmap. reflexivity.

  - (* monad_law_3 *) intros.
    rewrite <- prod_law_2.
    rewrite <- comp_id_left.
    rewrite <- (@monad_law_3 M _ (N X)).
    rewrite <- comp_assoc.
    rewrite <- comp_assoc.
    rewrite app_fmap_compose. simpl.
    rewrite <- fun_composition.
    rewrite <- comp_assoc.
    unfold compose_pure.
    rewrite <- app_fmap_compose.
    reflexivity.

  - (* monad_law_4 *) intros. simpl.
    unfold compose_fmap.
    unfold compose at 3.
    unfold compose at 3.
    unfold compose at 4.
    rewrite comp_assoc at 1.
    rewrite <- monad_law_4.
    repeat (rewrite <- comp_assoc).
    rewrite fun_composition.
    rewrite fun_composition.
    pose proof (@prod_law_1 M N _ _ _ X).
    simpl in H4.
    unfold compose_fmap in H4.
    unfold compose in H4 at 2.
    unfold compose in H4 at 3.
    rewrite <- H4.
    reflexivity.
Defined.
