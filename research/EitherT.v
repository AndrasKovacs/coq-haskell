Require Export Either.
Require Export MCompose.
Require Export Trans.
Require Export MMorph.

Inductive EitherT (X : Type) (M : Type -> Type) (Y : Type) : Type :=
  EitherT_ : M (Either X Y) -> EitherT X M Y.

Definition EitherT_map {E M} `{Functor M} {X Y}
  (f : X -> Y) (x : EitherT E M X) : EitherT E M Y :=
  match x with EitherT_ m => EitherT_ E M Y (fmap (fmap f) m) end.

Global Instance EitherT_Functor {E M} `{Functor M}
  : Functor (EitherT E M) :=
{ fmap := fun _ _ => EitherT_map
}.
Proof.
  - (* fun_identity *)
    intros.
    extensionality x.
    unfold EitherT_map.
    destruct x.
    repeat (rewrite fun_identity).
    unfold id.
    reflexivity.

  - (* fun_composition *)
    intros.
    extensionality x.
    unfold EitherT_map.
    destruct x.
    repeat (rewrite <- fun_composition).
    unfold compose.
    reflexivity.
Defined.

Definition EitherT_pure {E M} `{Applicative M} {X}
  : X -> EitherT E M X := EitherT_ E M X ∘ pure ∘ pure.

Definition EitherT_apply {E M} `{Applicative M} {X Y}
  (f : EitherT E M (X -> Y)) (x : EitherT E M X) : EitherT E M Y :=
  match f with
    EitherT_ mf => match x with
      EitherT_ mx => EitherT_ E M Y (ap (fmap ap mf) mx)
    end
  end.

Global Instance EitherT_Applicative {E M} `{Applicative M}
  : Applicative (EitherT E M) :=
{ is_functor := EitherT_Functor
; pure   := fun _ => EitherT_pure
; ap := fun _ _ => EitherT_apply
}.
Admitted.
(*
Proof.
  - (* app_identity *) intros. extensionality x.
    unfold EitherT_apply, EitherT_pure.
    destruct x.
    unfold id, compose.
    f_equal.
    apply (@app_identity_x (fun X => fobj (fobj X))
          (Applicative_Compose M (Either E))).

  - (* app_composition *) intros.
    unfold EitherT_apply, EitherT_pure.
    destruct u. destruct v. destruct w.
    unfold compose.
    f_equal.
    apply (@app_composition (fun X => fobj (fobj X))
          (Applicative_Compose M (Either E))).

  - (* app_homomorphism *) intros.
    unfold EitherT_apply, EitherT_pure. f_equal.
    unfold compose.
    f_equal.
    apply (@app_homomorphism (fun X => fobj (fobj X))
          (Applicative_Compose M (Either E))).

  - (* app_interchange *) intros.
    unfold EitherT_apply, EitherT_pure.
    destruct u.
    unfold compose.
    f_equal.
    apply (@app_interchange (fun X => fobj (fobj X))
          (Applicative_Compose M (Either E))).

  - (* app_fmap_unit *) intros.
    unfold EitherT_apply, EitherT_pure.
    unfold compose.
    f_equal.
    rewrite_app_homomorphisms.
    reflexivity.
Defined.
*)

Definition EitherT_join {E M} `{Monad M} {X}
  (x : EitherT E M (EitherT E M X)) : EitherT E M X :=
  match x with EitherT_ m =>
    EitherT_ E M X (join (fmap
      (fun y => match y with
       | Left e => pure (Left E X e)
       | Right (EitherT_ mx') => mx'
      end) m))
  end.

Global Instance EitherT_Monad {E M} `{Monad M}
  : Monad (EitherT E M) :=
{ is_applicative := EitherT_Applicative
; join := fun _ => EitherT_join
}.
Admitted.
(*
Proof.
  - (* monad_law_1 *) intros. extensionality x. simpl.
    unfold compose, EitherT_join.
    destruct x. simpl.
    f_equal. simpl.
    unfold Either_map.
    repeat (rewrite fun_composition_x).
    unfold compose.
    rewrite <- monad_law_4_x.
    unfold compose.
    rewrite <- monad_law_1_x.
    repeat (rewrite fun_composition_x).
    repeat f_equal.
    unfold compose.
    extensionality x. destruct x.
      rewrite <- app_fmap_unit.
        rewrite app_homomorphism.
        rewrite monad_law_3_x.
        reflexivity.
      destruct e. reflexivity.

  - (* monad_law_2 *) intros. extensionality x. simpl.
    unfold compose, EitherT_join, EitherT_pure.
    simpl. destruct x.
    unfold EitherT_map, id.
    simpl. f_equal.
    rewrite fun_composition_x.
    unfold compose, Either_map.
    rewrite <- uncompose with (f := join).
      assert ((fun x : Either E X =>
                 match
                   match x with
                   | Left e => Left E (EitherT E M X) e
                   | Right x' =>
                       Right E (EitherT E M X)
                         (EitherT_ E M X ((pure/M) (Right E X x')))
                   end
                 with
                 | Left e => (pure/M) (Left E X e)
                 | Right (EitherT_ mx') => mx'
                 end) = (@pure M _ (Either E X))).
        extensionality x. destruct x; reflexivity. rewrite H0. clear H0.
    apply monad_law_2_x.
    assumption.

  - (* monad_law_3 *) intros. extensionality x. simpl.
    unfold compose, EitherT_join, EitherT_pure.
    simpl. destruct x.
    unfold compose, id. f_equal.
    rewrite <- app_fmap_compose_x.
    rewrite <- uncompose with (f := join).
      rewrite monad_law_3. reflexivity.
      assumption.

  - (* monad_law_4 *) intros. extensionality x. simpl.
    unfold compose, EitherT_join, EitherT_map.
    simpl. destruct x. f_equal.
    rewrite <- monad_law_4_x.
    f_equal.
    repeat (rewrite fun_composition_x).
    unfold compose.
    f_equal. extensionality x.
    destruct x; simpl.
      unfold Either_map. simpl.
      rewrite <- app_fmap_compose_x. reflexivity.
      destruct e. reflexivity.
Defined.
*)

Global Instance EitherT_MonadTrans {E} {M : Type -> Type} `{Monad M}
  : MonadTrans (EitherT E) :=
{ lift := fun A => EitherT_ E M A ∘ fmap pure
}.
Admitted.
(*
Proof.
  - (* trans_law_1 *) intros. extensionality x.
    repeat (rewrite <- comp_assoc).
    rewrite <- app_fmap_compose.
    reflexivity.
  - (* trans_law_2 *) intros.
    unfold bind, compose. simpl.
    repeat (rewrite fun_composition_x).
    unfold compose. simpl. f_equal.
    rewrite <- monad_law_4_x. f_equal.
    rewrite fun_composition_x.
    reflexivity.
Defined.
*)

Global Instance EitherT_MFunctor {E}
  : MFunctor (EitherT E) :=
{ hoist := fun M N _ _ A nat m =>
    match m with
      EitherT_ m' => EitherT_ E N A (nat (Either E A) m')
    end
}.
Proof.
  - (* hoist_law_1 *) intros. extensionality x.
    destruct x. subst.
    reflexivity.
  - (* hoist_law_2 *) intros. extensionality x.
    destruct x.
    unfold compose.
    reflexivity.
Defined.

(*
Global Instance EitherT_MMonad {E}
  `{Monad (Either E)}
  : MMonad (EitherT E) EitherT_MFunctor EitherT_MonadTrans :=
{ embed := fun M N nd tnd A f m =>
    EitherT_ E N A (match m with
      EitherT_ m' => match f (Either E A) m' with
        EitherT_ m'' =>
          fmap (fun x => match x with
            | Left e => Left E A e
            | Right (Left e) => Left E A e
            | Right (Right x) => Right E A x
            end) m''
      end
    end)
}.
Proof.
  - (* embed_law_1 *) intros. extensionality x.
    destruct x.
    unfold id.
    f_equal.
    inversion td.
  - (* embed_law_2 *) intros.
  - (* embed_law_3 *) intros.
Defined.
*)