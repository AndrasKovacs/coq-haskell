Require Export Category.

Open Scope category_scope.

Set Primitive Projection.
Set Universe Polymorphism.
Generalizable All Variables.

Class Functor (C : Category) (D : Category) :=
{ fobj : C → D
; fmap : ∀ {X Y : C}, (X ~> Y) → (fobj X ~> fobj Y)

; fmap_respects : ∀ a b (f f' : a ~> b), f ≈ f' → fmap f ≈ fmap f'

; functor_id_law : ∀ {X : C}, fmap (id (A := X)) ≈ id
; functor_compose_law : ∀ {X Y Z : C} (f : Y ~> Z) (g : X ~> Y),
    fmap f ∘ fmap g ≈ fmap (f ∘ g)
}.

Notation "C ⟶ D" := (Functor C D) (at level 90, right associativity).

Add Parametric Morphism `(C : Category) `(D : Category) (F : C ⟶ D) (a b : C)
  : (@fmap C D F a b)
  with signature ((@eqv C a b) ==> (@eqv D (fobj a) (fobj b)))
    as parametric_morphism_fmap'.
  intros; apply (@fmap_respects C D F a b x y); auto.
Defined.

(* Functors used as functions will map objects of categories, similar to the
   way type constructors behave in Haskell. *)
Coercion fobj : Functor >-> Funclass.

(* jww (2014-08-11): Have the ∘ symbol refer to morphisms in any category, so
   that it can be used for both arrows and functors (which are arrows in
   Cat). *)
Program Instance fun_compose
  {C : Category} {D : Category} {E : Category}
  (F : Functor D E) (G : Functor C D) : Functor C E := {
    fobj := fun x => fobj (fobj x);
    fmap := fun _ _ f => fmap (fmap f)
}.
Obligation 1. crush. Defined.
Obligation 2.
  rewrite functor_id_law.
  apply functor_id_law.
Defined.
Obligation 3.
  rewrite functor_compose_law.
  rewrite functor_compose_law.
  reflexivity.
Defined.

Lemma fun_irrelevance `(C : Category) `(D : Category)
  : ∀ (a : C → D)
      (f g : ∀ {X Y : C}, (X ~> Y) → (a X ~> a Y))
      e e' i i' c c',
  @f = @g →
  {| fobj := @a
   ; fmap := @f
   ; fmap_respects       := e
   ; functor_id_law      := i
   ; functor_compose_law := c |} =
  {| fobj := @a
   ; fmap := @g
   ; fmap_respects       := e'
   ; functor_id_law      := i'
   ; functor_compose_law := c' |}.
Proof.
  intros. subst. f_equal.
  apply proof_irrelevance.
  apply proof_irrelevance.
  apply proof_irrelevance.
Qed.

(* The Identity [Functor] *)

Definition Id `{C : Category} : Functor C C.
  apply Build_Functor with
    (fobj := fun X => X)
    (fmap := fun X X f => f); crush.
Defined.

(* This is like JMEq, but for the particular case of ≈; note it does not
   require any axioms! *)

Inductive heq_morphisms `{C : Category} {a b : C} (f : a ~> b)
  : forall {a' b' : C}, a' ~> b' → Prop :=
  | heq_morphisms_intro : forall {f' : a ~> b},
      eqv f f' → @heq_morphisms C a b f a b f'.

Definition heq_morphisms_refl : forall `{C : Category} a b f,
  @heq_morphisms C a b f a  b  f.
Proof.
  intros; apply heq_morphisms_intro; reflexivity.
Qed.

Definition heq_morphisms_symm : forall `{C : Category} a b f a' b' f',
  @heq_morphisms C a b f a' b' f' → @heq_morphisms C a' b' f' a b f.
Proof.
  refine (fun C a b f a' b' f' isd =>
    match isd with
      | heq_morphisms_intro f''' z => @heq_morphisms_intro C _ _ f''' f _
    end); symmetry; auto.
Qed.

Definition heq_morphisms_tran
  : forall `{C : Category} a b f a' b' f' a'' b'' f'',
  @heq_morphisms C a b f a' b' f' ->
  @heq_morphisms C a' b' f' a'' b'' f'' ->
  @heq_morphisms C a b f a'' b'' f''.
  destruct 1.
  destruct 1.
  apply heq_morphisms_intro.
  setoid_rewrite <- H0.
  apply H.
Qed.

Implicit Arguments heq_morphisms [C a b a' b'].
Hint Constructors heq_morphisms.

Definition EqualFunctors `{C : Category} `{D : Category}
  (F : Functor C D) (G : Functor C D) :=
  forall a b (f f' : a ~{C}~> b), f ≈ f' → heq_morphisms (fmap f) (fmap f').

Notation "f ~~~ g" := (EqualFunctors f g) (at level 45).

Lemma fun_left_identity `(F : @Functor C D) : fun_compose Id F ~~~ F.
Proof.
  destruct F.
  unfold fun_compose.
  simpl. unfold EqualFunctors.
  intros. constructor. simpl.
  apply fmap_respects0. assumption.
Qed.

Lemma fun_right_identity `(F : @Functor C D) : fun_compose F Id ~~~ F.
Proof.
  destruct F.
  unfold fun_compose.
  simpl. unfold EqualFunctors.
  intros. constructor. simpl.
  apply fmap_respects0. assumption.
Qed.

(** [Cat] is the category whose morphisms are functors betwen categories.
    jww (2014-08-24): Coq 8.5 with universe polymorphism is needed. *)

(*
Section Hidden.

Program Instance Cat : Category :=
{ ob      := Category
; hom     := @Functor
; id      := @Id
; compose := @fun_compose
}.
Obligation 1.
  unfold fun_compose.
  destruct f.
  apply fun_irrelevance.
  extensionality e.
  extensionality f.
  extensionality g.
  reflexivity.
Defined.
Obligation 2.
  unfold fun_compose.
  destruct f.
  apply fun_irrelevance.
  extensionality e.
  extensionality f.
  extensionality g.
  reflexivity.
Defined.
Obligation 3.
  unfold fun_compose.
  destruct f.
  apply fun_irrelevance.
  extensionality e.
  extensionality f.
  reflexivity.
Defined.

Program Instance One : Category := {
    ob      := unit;
    hom     := fun _ _ => unit;
    id      := fun _ => tt;
    compose := fun _ _ _ _ _ => tt
}.
Obligation 1. destruct f. reflexivity. Qed.
Obligation 2. destruct f. reflexivity. Qed.

Program Instance Fini `(C : Category) : C ⟶ One := {
    fobj    := fun _ => tt;
    fmap    := fun _ _ _ => id
}.

Program Instance Zero : Category := {
    ob      := Empty_set;
    hom     := fun _ _ => Empty_set
}.
Obligation 3.
    unfold Zero_obligation_1.
    unfold Zero_obligation_2.
    destruct A.
Defined.

Program Instance Init `(C : Category) : Zero ⟶ C.
Obligation 1. destruct C. crush. Defined.
Obligation 2.
  unfold Init_obligation_1.
  destruct C. crush.
Defined.
Obligation 3.
  unfold Zero_obligation_1.
  unfold Init_obligation_1.
  unfold Init_obligation_2.
  destruct C. crush.
Defined.
Obligation 4.
  unfold Init_obligation_2.
  unfold Zero_obligation_2.
  destruct C. crush.
Qed.

Class HasInitial (C : Category) :=
{ init_obj    : C
; init_mor    : ∀ {X}, init_obj ~> X
; initial_law : ∀ {X} (f g : init_obj ~> X), f = g
}.

Program Instance Cat_HasInitial : HasInitial Cat := {
    init_obj := Zero;
    init_mor := Init
}.
Obligation 1.
  induction f as [F].
  induction g as [G].
  assert (F = G).
    extensionality e.
    crush.
  replace F with G. subst.
  assert (fmap0 = fmap1).
    extensionality e.
    extensionality f.
    extensionality g.
    crush.
  apply fun_irrelevance.
  assumption.
Qed.

Class HasTerminal (C : Category) :=
{ term_obj     : C
; term_mor     : ∀ {X}, X ~> term_obj
; terminal_law : ∀ {X} (f g : X ~> term_obj), f = g
}.

Program Instance Cat_HasTerminal : HasTerminal Cat := {
    term_obj := One;
    term_mor := Fini
}.
Obligation 1.
  destruct f as [F].
  destruct g as [G].
  assert (F = G).
    extensionality e.
    crush.
  replace F with G. subst.
  assert (fmap0 = fmap1).
    extensionality e.
    extensionality f.
    extensionality g.
    crush.
  apply fun_irrelevance.
  assumption.
Qed.

End Hidden.
*)

Class Natural `(F : @Functor C D) `(G : @Functor C D) :=
{ transport  : ∀ {X}, F X ~> G X
; naturality : ∀ {X Y} (f : X ~> Y),
    fmap f ∘ transport ≈ transport ∘ fmap f
}.

Notation "transport/ N" := (@transport _ _ _ _ N _) (at level 44).
Notation "F ⟾ G" := (Natural F G) (at level 90, right associativity).

(* Natural transformations can be applied directly to functorial values to
   perform the functor mapping they imply. *)
Coercion transport : Natural >-> Funclass.

Program Instance nat_identity `{F : Functor} : F ⟾ F := {
    transport := fun _ => id
}.
Obligation 1.
  rewrite right_identity.
  rewrite left_identity.
  reflexivity.
Defined.

Program Instance nat_compose `{F : C ⟶ D} `{G : C ⟶ D} `{K : C ⟶ D}
  (f : G ⟾ K) (g : F ⟾ G) : F ⟾ K := {
    transport := fun X =>
      @transport C D G K f X ∘ @transport C D F G g X
}.
Obligation 1.
  rewrite comp_assoc.
  rewrite naturality.
  rewrite <- comp_assoc.
  rewrite naturality.
  rewrite comp_assoc.
  reflexivity.
Defined.

Section NaturalEquiv.

Context `{C : Category}.
Context `{D : Category}.
Context `{F : C ⟶ D}.
Context `{G : C ⟶ D}.

Lemma nat_irrelevance : ∀ (f g : ∀ {X}, F X ~> G X) n n',
  @f = @g ->
  {| transport := @f; naturality := n |} =
  {| transport := @g; naturality := n' |}.
Proof.
  intros. subst. f_equal.
  apply proof_irrelevance.
Qed.

Definition nat_equiv (x y : F ⟾ G) : Prop :=
  match x with
  | Build_Natural transport0 _ => match y with
    | Build_Natural transport1 _ => forall {X}, transport0 X ≈ transport1 X
    end
  end.

Program Instance nat_equivalence : Equivalence nat_equiv.
Obligation 1.
  unfold Reflexive, nat_equiv. intros.
  destruct x. auto.
Defined.
Obligation 2.
  unfold Symmetric, nat_equiv. intros.
  destruct x. destruct y. intros.
  specialize (H X).
  symmetry; assumption.
Defined.
Obligation 3.
  unfold Transitive, nat_equiv. intros.
  destruct x. destruct y. destruct z.
  intros. specialize (H X). specialize (H0 X).
  transitivity (transport1 X); assumption.
Defined.

End NaturalEquiv.

Add Parametric Relation
  `(C : Category) `(D : Category) `(F : C ⟶ D) `(G : C ⟶ D)
  : (F ⟾ G) (@nat_equiv C D F G)
  reflexivity proved by  (@Equivalence_Reflexive  _ _ (@nat_equivalence C D F G))
  symmetry proved by     (@Equivalence_Symmetric  _ _ (@nat_equivalence C D F G))
  transitivity proved by (@Equivalence_Transitive _ _ (@nat_equivalence C D F G))
    as parametric_relation_nat_eqv.

  Add Parametric Morphism
    `(C : Category) `(D : Category) `(F : C ⟶ D) `(G : C ⟶ D) `(K : C ⟶ D)
    : (@nat_compose C D F G K)
    with signature (nat_equiv ==> nat_equiv ==> nat_equiv)
      as parametric_morphism_nat_comp.
    intros. unfold nat_equiv, nat_compose.
    destruct x. destruct y. destruct x0. destruct y0.
    simpl in *. intros.
    specialize (H0 X). rewrite H0. auto.
Defined.

(* Nat is the category whose morphisms are natural transformations between
   Functors from C ⟶ D. *)

Program Instance Nat (C : Category) (D : Category) : Category :=
{ ob      := Functor C D
; hom     := @Natural C D
; id      := @nat_identity C D
; compose := @nat_compose C D
; eqv     := @nat_equiv C D
}.
Obligation 1. (* right_identity *)
  destruct f. intros.
  rewrite right_identity. reflexivity.
Defined.
Obligation 2. (* left_identity *)
  destruct f. intros.
  rewrite left_identity. reflexivity.
Defined.
Obligation 3. (* comp_assoc *)
  destruct f. destruct g. destruct h. simpl.
  rewrite <- comp_assoc. reflexivity.
Defined.

Notation "[ C , D ]" := (Nat C D) (at level 90, right associativity).

Definition Copresheaves (C : Category) := [C, Sets].
Definition Presheaves   (C : Category) := [C^op, Sets].

(*
Bifunctors can be curried:

  C × D ⟶ E   -->  C ⟶ [D, E]
  ~~~
  (C, D) -> E  -->  C -> D -> E

Where ~~~ should be read as "Morally equivalent to".

Note: We do not need to define Bifunctors as a separate class, since they can
be derived from functors mapping to a category of functors.  So in the
following two definitions, [P] is effectively our bifunctor.

The trick to [bimap] is that both the [Functor] instances we need (for [fmap]
and [fmap1]), and the [Natural] instance, can be found in the category of
functors we're mapping to by applying [P].
*)

Definition fmap1 `{P : C ⟶ [D, E]} {A : C} `(f : X ~{D}~> Y) :
  P A X ~{E}~> P A Y := fmap f.

Definition bimap `{P : C ⟶ [D, E]} {X W : C} {Y Z : D} (f : X ~{C}~> W) (g : Y ~{D}~> Z) :
  P X Y ~{E}~> P W Z := let N := @fmap _ _ P _ _ f in transport/N ∘ fmap1 g.

Definition contramap `{F : C^op ⟶ D} `(f : X ~{C}~> Y) :
  F Y ~{D}~> F X := fmap (unop f).

Definition dimap `{P : C^op ⟶ [D, E]} `(f : X ~{C}~> W) `(g : Y ~{D}~> Z) :
  P W Y ~{E}~> P X Z := bimap (unop f) g.

(* jww (2014-08-24): Waiting on Coq 8.5. *)
(*
Program Instance Hom `(C : Category) : C^op ⟶ [C, Sets] :=
{ fobj := fun X =>
  {| fobj := @hom C X
   ; fmap := @compose C X
   ; fmap_respects := fun a b f f' H => @eqv_equivalence C a b
   |}
; fmap := fun _ _ f => {| transport := fun X g => g ∘ unop f |}
}.
Obligation 1.
  remove_equivs. f_equal.
  extensionality x. apply H0.
Defined.
Obligation 2. intros. extensionality e. crush. Defined.
Obligation 3. extensionality e. crush. Defined.
Obligation 4.
  unfold nat_identity.
  apply nat_irrelevance.
  extensionality e.
  extensionality f.
  unfold unop.
  rewrite right_identity.
  auto.
Defined.
Obligation 5.
  unfold nat_compose, nat_identity.
  apply nat_irrelevance.
  extensionality e.
  simpl.
  unfold unop.
  extensionality h.
  crush.
Defined.

Coercion Hom : Category >-> Functor.
*)

(*
(** This is the Yoneda embedding. *)
(* jww (2014-08-10): It should be possible to get rid of Hom here, but the
   coercion isn't firing. *)
Program Instance Yoneda `(C : Category) : C ⟶ [C^op, Sets] := Hom (C^op).
Obligation 1. apply op_involutive. Defined.
*)

(*
Program Instance YonedaLemma `(C : Category) `(F : C ⟶ Sets) {A : C^op}
    : (C A ⟾ F) ≅Sets F A.
Obligation 1.
  intros.
  destruct X.
  apply transport0.
  simpl.
  destruct C.
  crush.
Defined.
Obligation 2.
  intros.
  simpl.
  pose (@fmap C Sets F A).
  apply Build_Natural with (transport := fun Y φ => h Y φ X).
  intros.
  inversion F. simpl.
  extensionality e.
  unfold h.
  rewrite <- functor_compose_law.
  crush.
Defined.
Obligation 3.
  extensionality e.
  pose (f := fun (_ : unit) => e).
  destruct C.
  destruct F. simpl.
  rewrite functor_id_law0.
  crush.
Qed.
Obligation 4.
  extensionality e.
  destruct e.
  simpl.
  apply nat_irrelevance.
  extensionality f.
  extensionality g.
  destruct C as [ob0 uhom0 hom0 id0].
  destruct F.
  simpl.
  assert (fmap0 A f g (transport0 A (id0 A)) =
          (fmap0 A f g ∘ transport0 A) (id0 A)).
    crush. rewrite H. clear H.
  rewrite naturality0.
  crush.
Qed.
*)

Class FullyFaithful `(F : @Functor C D) :=
{ unfmap : ∀ {X Y : C}, (F X ~> F Y) → (X ~> Y)
}.

(*
Program Instance Hom_Faithful (C : Category) : FullyFaithful C :=
{ unfmap := fun _ _ f => (transport/f) id
}.
*)

(*
Program Instance Hom_Faithful_Co (C : Category) {A : C} : FullyFaithful (C A).
Obligation 1.
  destruct C. crush.
  clear left_identity.
  clear right_identity.
  clear comp_assoc.
  specialize (compose X A Y).
  apply compose in X0.
    assumption.
  (* jww (2014-08-12): Is this even provable?  Ed thinks no. *)
*)

(** ** Opposite functor[edit]

Every functor [F: C ⟶ D] induces the opposite functor [F^op]: [C^op ⟶ D^op],
where [C^op] and [D^op] are the opposite categories to [C] and [D].  By
definition, [F^op] maps objects and morphisms identically to [F].

*)

Program Instance Opposite_Functor `(F : C ⟶ D) : C^op ⟶ D^op := {
    fobj := @fobj C D F;
    fmap := fun X Y f => @fmap C D F Y X (op f)
}.
Obligation 1. unfold op. rewrite H. reflexivity. Qed.
Obligation 2. unfold op. apply functor_id_law. Qed.
Obligation 3. unfold op. apply functor_compose_law. Qed.

(* jww (2014-08-10): Until I figure out how to make C^op^op implicitly unify
   with C, I need a way of undoing the action of Opposite_Functor. *)

Program Instance Reverse_Opposite_Functor `(F : C^op ⟶ D^op) : C ⟶ D := {
    fobj := @fobj _ _ F;
    fmap := fun X Y f => unop (@fmap _ _ F Y X f)
}.
Obligation 1.
  destruct F.
  unfold Opposite.
  simpl in *.
  admit.
Defined.
Obligation 2. admit. Defined.
Obligation 3. admit. Defined.
Obligation 4.
  unfold unop.
  unfold fmap. simpl.
  pose (@functor_id_law _ _ F).
  unfold fmap in e. simpl in e.
  specialize (e X). auto.
Admitted.
Obligation 5.
  unfold unop.
  unfold fmap. simpl.
  pose (@functor_compose_law _ _ F).
  unfold fmap in e. simpl in e.
  (* specialize (e Z Y X f f'). *)
  auto.
Admitted.
Obligation 6.
  unfold unop.
  pose (@functor_id_law _ _ F).
  simpl in *.
  specialize (e X).
  auto.
Admitted.
Obligation 7.
  unfold unop.
  unfold fmap. simpl.
  pose (@functor_compose_law _ _ F).
  unfold fmap in e. simpl in e.
  specialize (e Z Y X g f).
  auto.
Admitted.

(* Definition Coerce_Functor `(F : C ⟶ D) := Opposite_Functor F. *)

(* Coercion Coerce_Functor : Functor >-> Functor. *)

Lemma op_functor_involutive `(F : Functor)
  : Reverse_Opposite_Functor (Opposite_Functor F) ~~~ F.
Proof.
  unfold Reverse_Opposite_Functor.
  unfold Opposite_Functor.
  destruct F. simpl.
  unfold EqualFunctors. intros.
  simpl. constructor. auto.
Qed.

(*
Class Adjunction `{C : Category} `{D : Category}
    `(F : @Functor D C) `(U : @Functor C D) := {
    adj : ∀ (a : D) (b : C), (C (F a) b) ≅ (D a (U b))
}.

Notation "F ⊣ G" := (Adjunction F G) (at level 70) : category_scope.

Program Instance adj_identity `{C : Category} : Id ⊣ Id.

(* Definition adj' `{C : Category} `{D : Category} `{E : Category} *)
(*    (F : Functor D C) (U : Functor C D) *)
(*    (F' : Functor E D) (U' : Functor D E)  (a : E) (b : C) *)
(*    : (C (fun_compose F F' a) b) ≅ (E a (fun_compose U' U b)). *)

Definition adj_compose `{C : Category} `{D : Category} `{E : Category}
   (F : Functor D C) (U : Functor C D)
   (F' : Functor E D) (U' : Functor D E)
   (X : F ⊣ U) (Y : F' ⊣ U')
   : @fun_compose E D C F F' ⊣ @fun_compose C D E U' U.
Proof.
  destruct X.
  destruct Y.
  apply (@Build_Adjunction C E (@fun_compose E D C F F') (@fun_compose C D E U' U)).
  intros.
  specialize (adj0 (F' a) b).
  specialize (adj1 a (U b)).
  replace ((E a) ((fun_compose U' U) b)) with ((E a) ((U' (U b)))).
  replace ((C ((fun_compose F F') a)) b) with ((C (F (F' a))) b).
  apply (@iso_compose Sets ((C (F (F' a))) b) ((D (F' a)) (U b)) ((E a) (U' (U b)))).
  assumption.
  assumption.
  crush.
  crush.
Qed.

Record Adj_Morphism `{C : Category} `{D : Category} := {
    free_functor : Functor D C;
    forgetful_functor : Functor C D;
    adjunction : free_functor ⊣ forgetful_functor
}.

(* Lemma adj_left_identity `(F : @Functor D C) `(U : @Functor C D) *)
(*   : adj_compose Id Id F U adj_identity (F ⊣ U) = F ⊣ U. *)
(* Proof. *)
(*   destruct F. *)
(*   unfold fun_compose. *)
(*   simpl. *)
(*   apply fun_irrelevance. *)
(*   extensionality e. *)
(*   extensionality f. *)
(*   extensionality g. *)
(*   reflexivity. *)
(* Qed. *)

(* Lemma adj_right_identity `(F : @Functor C D) : fun_compose F Id = F. *)
(* Proof. *)
(*   destruct F. *)
(*   unfold fun_compose. *)
(*   simpl. *)
(*   apply fun_irrelevance. *)
(*   extensionality e. *)
(*   extensionality f. *)
(*   extensionality g. *)
(*   reflexivity. *)
(* Qed. *)

Lemma adj_irrelevance
   `{C : Category} `{D : Category} `{E : Category}
   (F F' : Functor D C) (U U' : Functor C D)
  : ∀ (X : F ⊣ U) (X' : F' ⊣ U'),
  @F = @F' →
  @U = @U' →
  {| free_functor      := @F
   ; forgetful_functor := @U
   ; adjunction        := @X
   |} =
  {| free_functor      := @F'
   ; forgetful_functor := @U'
   ; adjunction        := @X'
   |}.
Proof.
  intros. subst. f_equal.
  apply proof_irrelevance.
Qed.

Program Instance Adj : Category := {
    ob := Category;
    hom := @Adj_Morphism
}.
Obligation 1.
  apply Build_Adj_Morphism
    with (free_functor      := Id)
         (forgetful_functor := Id).
  apply adj_identity.
Defined.
Obligation 2.
  destruct X.
  destruct X0.
  apply Build_Adj_Morphism
    with (free_functor      := fun_compose free_functor1 free_functor0)
         (forgetful_functor := fun_compose forgetful_functor0 forgetful_functor1).
  apply adj_compose.
  assumption.
  assumption.
Defined.
Obligation 3.
  unfold Adj_obligation_2.
  unfold Adj_obligation_1.
  destruct f.
  destruct adjunction0.
  simpl.
  pose (fun_left_identity free_functor0).
  pose (fun_right_identity forgetful_functor0).
  apply adj_irrelevance.
  rewrite e. reflexivity.
  rewrite e0. reflexivity.
Qed.
Obligation 4.
  unfold Adj_obligation_2.
  unfold Adj_obligation_1.
  destruct f.
  destruct adjunction0.
  simpl.
  pose (fun_left_identity forgetful_functor0).
  pose (fun_right_identity free_functor0).
  apply adj_irrelevance.
  rewrite e0. reflexivity.
  rewrite e. reflexivity.
Qed.
Obligation 5.
  admit.
Qed.
*)

(* Inductive Const := Const_ : Type → Const. *)

(* Definition getConst `{C : Category} (c : @Const C) : C := *)
(*   match c with *)
(*   | Const_ x => x *)
(*   end. *)

Program Instance Const `{C : Category} `{J : Category} (x : C) : J ⟶ C := {
    fobj := fun _ => x;
    fmap := fun _ _ _ => id
}.

Lemma Const_Iso `{C : Category} : ∀ a b, Const a b ≅ a.
Proof. crush. Qed.

Definition Sets_getConst `{J : Category} (a : Type) (b : J)
  (c : @Const Sets J a b) : Type := @fobj J Sets (@Const Sets J a) b.

Program Instance Const_Transport `(C : Category) `(J : Category) `(x ~> y)
  : @Natural C J (Const x) (Const y) := {
    transport := fun X => _
}.
Obligation 2.
  rewrite left_identity.
  rewrite right_identity. reflexivity.
Defined.

Hint Unfold Const_Transport_obligation_1.

Program Instance Delta `{C : Category} `{J : Category} : C ⟶ [J, C] := {
    fobj := @Const C J;
    fmap := @Const_Transport J C
}.
Obligation 2. autounfold. reflexivity. Qed.
Obligation 3. autounfold. reflexivity. Qed.

(*
Class Complete `(C : Category) := {
    complete : ∀ (J : Category), { Lim : [J, C] ⟶ C & @Delta C J ⊣ Lim }
}.
*)

(* Here F is a diagram of type J in C. *)
Record Cone `{C : Category} `{J : Category} (n : C) `(F : @Functor J C) := {
    cone_mor : ∀ j : J, n ~> F j;
    cone_law : ∀ i j (f : i ~{J}~> j), (@fmap J C F i j f) ∘ cone_mor i ≈ cone_mor j
}.

Definition Const_to_Cone `(F : J ⟶ C) {a} : (Const a ⟾ F) → Cone a F.
Proof.
  intros.
  destruct X.
  apply Build_Cone
    with (cone_mor := transport0).
  intros. simpl in *.
  specialize (naturality0 i j f).
  rewrite right_identity in naturality0.
  apply naturality0.
Defined.

Definition Cone_to_Const `(F : J ⟶ C) {a} : Cone a F → (Const a ⟾ F).
Proof.
  intros.
  simpl. intros.
  unfold Const.
  destruct X.
  refine (Build_Natural _ _ _ _ _ _); intros; simpl.
  crush.
Defined.

(* jww (2014-08-24): Needs Coq 8.5.
Lemma Const_Cone_Iso `(F : J ⟶ C) : ∀ a, (Const a ⟾ F) ≅Sets Cone a F.
Proof.
  intros.
  apply Build_Isomorphism
    with (to   := @Const_to_Cone J C F a)
         (from := @Cone_to_Const J C F a);
  reduce; extensionality e; auto.
Qed.
*)

(*
Program Instance Lim_Sets `(J : Category) : [J, Sets] ⟶ Sets := {
    fobj := fun F => 
    fmap := fun _ _ n F_x z => (transport/n) (F_x z)
}.

Lemma distribute_forall : ∀ a {X} P, (a → ∀ (x : X), P x) → (∀ x, a → P x).
Proof.
  intros.
  apply X0.
  assumption.
Qed.

Lemma forall_distribute : ∀ a {X} P, (∀ x, a → P x) → (a → ∀ (x : X), P x).
Proof.
  intros.
  apply X0.
  assumption.
Qed.

Program Instance Sets_Const_Nat (J : Category) (F : [J, Sets])
  (a : Type) (f : a → ∀ x : J, F x) : @Const Sets J a ⟾ F.
Obligation 2.
  extensionality e.
  unfold Sets_Const_Nat_obligation_1.
  remember (f e) as j.
  destruct F. simpl. clear.
  destruct J.
  crush. clear.
  (* jww (2014-08-12): We don't believe this is true. *)

Program Instance Sets_Const_Lim_Iso (J : Category) (a : Sets) (F : [J, Sets])
  : @Isomorphism Sets (Const a ⟾ F) (a → Lim_Sets J F).
Obligation 1.
  destruct F. simpl.
  destruct X.
  apply transport0.
  auto.
Defined.
Obligation 2.
  apply Sets_Const_Nat.
  auto.
Defined.
Obligation 3.
  extensionality e.
  unfold Sets_Const_Lim_Iso_obligation_1.
  unfold Sets_Const_Lim_Iso_obligation_2.
  extensionality f.
  extensionality g.
  destruct F. simpl.
  unfold Sets_Const_Nat_obligation_1.
  reflexivity.
Qed.
Obligation 4.
  extensionality e.
  unfold Sets_Const_Lim_Iso_obligation_1.
  unfold Sets_Const_Lim_Iso_obligation_2.
  unfold Sets_Const_Nat.
  destruct e.
  unfold Sets_Const_Nat_obligation_1.
  unfold Sets_Const_Nat_obligation_2.
  apply nat_irrelevance.
  extensionality f.
  extensionality g.
  destruct F. simpl.
  reflexivity.
Qed.

Program Instance Sets_Complete : Complete Sets.
Obligation 1.
  exists (Lim_Sets J).
  apply Build_Adjunction.
  intros. simpl.
  apply Sets_Const_Lim_Iso.
Qed.
*)
