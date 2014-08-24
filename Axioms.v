Require Export FunctionalExtensionality.

Axiom propositional_extensionality : forall P : Prop, P -> P = True.
Axiom proof_irrelevance : forall (P : Prop) (u v : P), u = v.
