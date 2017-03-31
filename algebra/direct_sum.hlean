/-
Copyright (c) 2015 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn, Egbert Rijke

Constructions with groups
-/

import .quotient_group .free_commutative_group

open eq algebra is_trunc set_quotient relation sigma prod sum list trunc function equiv sigma.ops

namespace group

  variables {G G' : Group} (H : subgroup_rel G) (N : normal_subgroup_rel G) {g g' h h' k : G}
            {A B : AbGroup}

  variables (X : Set) {l l' : list (X ⊎ X)}

  section

    parameters {I : Set} (Y : I → AbGroup)
    variables {A' : AbGroup} {Y' : I → AbGroup}

    definition dirsum_carrier : AbGroup := free_ab_group (trunctype.mk (Σi, Y i) _)
    local abbreviation ι [constructor] := @free_ab_group_inclusion
    inductive dirsum_rel : dirsum_carrier → Type :=
    | rmk : Πi y₁ y₂, dirsum_rel (ι ⟨i, y₁⟩ * ι ⟨i, y₂⟩ * (ι ⟨i, y₁ * y₂⟩)⁻¹)

    definition dirsum : AddAbGroup := quotient_ab_group_gen dirsum_carrier (λg, ∥dirsum_rel g∥)

    -- definition dirsum_carrier_incl [constructor] (i : I) : Y i →g dirsum_carrier :=

    definition dirsum_incl [constructor] (i : I) : Y i →g dirsum :=
    homomorphism.mk (λy, class_of (ι ⟨i, y⟩))
      begin intro g h, symmetry, apply gqg_eq_of_rel, apply tr, apply dirsum_rel.rmk end

    parameter {Y}
    definition dirsum.rec {P : dirsum → Type} [H : Πg, is_prop (P g)]
      (h₁ : Πi (y : Y i), P (dirsum_incl i y)) (h₂ : P 1) (h₃ : Πg h, P g → P h → P (g * h)) :
      Πg, P g :=
    begin
      refine @set_quotient.rec_prop _ _ _ H _,
      refine @set_quotient.rec_prop _ _ _ (λx, !H) _,
      esimp, intro l, induction l with s l ih,
        exact h₂,
      induction s with v v,
        induction v with i y,
        exact h₃ _ _ (h₁ i y) ih,
      induction v with i y,
      refine h₃ (gqg_map _ _ (class_of [inr ⟨i, y⟩])) _ _ ih,
      refine transport P _ (h₁ i y⁻¹),
      refine _ ⬝ !one_mul,
      refine _ ⬝ ap (λx, mul x _) (to_respect_one (dirsum_incl i)),
      apply gqg_eq_of_rel',
      apply tr, esimp,
      refine transport dirsum_rel _ (dirsum_rel.rmk i y⁻¹ y),
      rewrite [mul.left_inv, mul.assoc],
    end

    definition dirsum_homotopy {φ ψ : dirsum →g A'}
      (h : Πi (y : Y i), φ (dirsum_incl i y) = ψ (dirsum_incl i y)) : φ ~ ψ :=
    begin
      refine dirsum.rec _ _ _,
          exact h,
        refine !respect_one ⬝ !respect_one⁻¹,
      intro g₁ g₂ h₁ h₂, rewrite [+ to_respect_mul, h₁, h₂]
    end

    definition dirsum_elim_resp_quotient (f : Πi, Y i →g A') (g : dirsum_carrier)
      (r : ∥dirsum_rel g∥) : free_ab_group_elim (λv, f v.1 v.2) g = 1 :=
    begin
      induction r with r, induction r,
      rewrite [to_respect_mul, to_respect_inv], apply mul_inv_eq_of_eq_mul,
      rewrite [one_mul, to_respect_mul, ▸*, ↑foldl, +one_mul, to_respect_mul]
    end

    definition dirsum_elim [constructor] (f : Πi, Y i →g A') : dirsum →g A' :=
    gqg_elim _ (free_ab_group_elim (λv, f v.1 v.2)) (dirsum_elim_resp_quotient f)

    definition dirsum_elim_compute (f : Πi, Y i →g A') (i : I) :
      dirsum_elim f ∘g dirsum_incl i ~ f i :=
    begin
      intro g, apply one_mul
    end

    definition dirsum_elim_unique (f : Πi, Y i →g A') (k : dirsum →g A')
      (H : Πi, k ∘g dirsum_incl i ~ f i) : k ~ dirsum_elim f :=
    begin
      apply gqg_elim_unique,
      apply free_ab_group_elim_unique,
      intro x, induction x with i y, exact H i y
    end

  end

  variables {I J : Set} {Y Y' Y'' : I → AddAbGroup}

  definition dirsum_functor [constructor] (f : Πi, Y i →g Y' i) : dirsum Y →g dirsum Y' :=
  dirsum_elim (λi, dirsum_incl Y' i ∘g f i)

  theorem dirsum_functor_compose (f' : Πi, Y' i →g Y'' i) (f : Πi, Y i →g Y' i) :
    dirsum_functor f' ∘g dirsum_functor f ~ dirsum_functor (λi, f' i ∘g f i) :=
  begin
    apply dirsum_homotopy,
    intro i y, reflexivity,
  end

  variable (Y)
  definition dirsum_functor_gid : dirsum_functor (λi, gid (Y i)) ~ gid (dirsum Y) :=
  begin
    apply dirsum_homotopy,
    intro i y, reflexivity,
  end
  variable {Y}

  definition dirsum_functor_add (f f' : Πi, Y i →g Y' i) :
    homomorphism_add (dirsum_functor f) (dirsum_functor f') ~
    dirsum_functor (λi, homomorphism_add (f i) (f' i)) :=
  begin
    apply dirsum_homotopy,
    intro i y, exact sorry
  end

  definition dirsum_functor_homotopy {f f' : Πi, Y i →g Y' i} (p : f ~2 f') :
    dirsum_functor f ~ dirsum_functor f' :=
  begin
    apply dirsum_homotopy,
    intro i y, exact sorry
  end

  definition dirsum_functor_left [constructor] (f : J → I) : dirsum (Y ∘ f) →g dirsum Y :=
  dirsum_elim (λj, dirsum_incl Y (f j))

end group
