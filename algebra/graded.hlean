/- Graded (left-) R-modules for a ring R. -/

-- Author: Floris van Doorn

import .left_module .direct_sum .submodule --..heq

open is_trunc algebra eq left_module pointed function equiv is_equiv prod group sigma nat

-- move
  lemma le_sub_of_add_le {n m k : ℕ} (h : n + m ≤ k) : n ≤ k - m :=
  begin
    induction h with k h IH,
    { exact le_of_eq !nat.add_sub_cancel⁻¹ },
    { exact le.trans IH (nat.sub_le_sub_right !self_le_succ _) }
  end

  lemma iterate_sub {A : Type} (f : A ≃ A) {n m : ℕ} (h : n ≥ m) (a : A) :
    iterate f (n - m) a = iterate f n (iterate f⁻¹ m a) :=
  begin
    revert n h, induction m with m p: intro n h,
    { reflexivity },
    { cases n with n, exfalso, apply not_succ_le_zero _ h,
      rewrite [succ_sub_succ], refine p n (le_of_succ_le_succ h) ⬝ _,
      refine ap (_^[n]) _ ⬝ !iterate_succ⁻¹, exact !to_right_inv⁻¹ }
  end

  definition iterate_commute {A : Type} {f g : A → A} (n : ℕ) (h : f ∘ g ~ g ∘ f) :
    iterate f n ∘ g ~ g ∘ iterate f n :=
  by induction n with n IH; reflexivity; exact λx, ap f (IH x) ⬝ !h

  definition iterate_equiv {A : Type} (f : A ≃ A) (n : ℕ) : A ≃ A :=
  equiv.mk (iterate f n)
           (by induction n with n IH; apply is_equiv_id; exact is_equiv_compose f (iterate f n))

  definition iterate_inv {A : Type} (f : A ≃ A) (n : ℕ) :
    (iterate_equiv f n)⁻¹ ~ iterate f⁻¹ n :=
  begin
    induction n with n p: intro a,
      reflexivity,
      exact p (f⁻¹ a) ⬝ !iterate_succ⁻¹
  end

namespace left_module

definition graded [reducible] (str : Type) (I : Type) : Type := I → str
definition graded_module [reducible] (R : Ring) : Type → Type := graded (LeftModule R)

variables {R : Ring} {I : Set} {M M₁ M₂ M₃ : graded_module R I}

/-
  morphisms between graded modules.
  The definition is unconventional in two ways:
  (1) The degree is determined by an endofunction instead of a element of I (and in this case we
    don't need to assume that I is a group). The "standard" degree i corresponds to the endofunction
    which is addition with i on the right. However, this is more flexible. For example, the
    composition of two graded module homomorphisms φ₂ and φ₁ with degrees i₂ and i₁ has type
    M₁ i → M₂ ((i + i₁) + i₂).
    However, a homomorphism with degree i₁ + i₂ must have type
    M₁ i → M₂ (i + (i₁ + i₂)),
    which means that we need to insert a transport. With endofunctions this is not a problem:
    λi, (i + i₁) + i₂
    is a perfectly fine degree of a map
  (2) Since we cannot eliminate all possible transports, we don't define a homomorphism as function
    M₁ i →lm M₂ (i + deg f)  or  M₁ i →lm M₂ (deg f i)
    but as a function taking a path as argument. Specifically, for every path
    deg f i = j
    we get a function M₁ i → M₂ j.
  (3) Note: we do assume that I is a set. This is not strictly necessary, but it simplifies things
-/

definition graded_hom_of_deg (d : I ≃ I) (M₁ M₂ : graded_module R I) : Type :=
Π⦃i j : I⦄ (p : d i = j), M₁ i →lm M₂ j

definition gmd_constant [constructor] (d : I ≃ I) (M₁ M₂ : graded_module R I) : graded_hom_of_deg d M₁ M₂ :=
λi j p, lm_constant (M₁ i) (M₂ j)

definition gmd0 [constructor] {d : I ≃ I} {M₁ M₂ : graded_module R I} : graded_hom_of_deg d M₁ M₂ :=
gmd_constant d M₁ M₂

structure graded_hom (M₁ M₂ : graded_module R I) : Type :=
mk' ::  (d : I ≃ I)
        (fn' : graded_hom_of_deg d M₁ M₂)

notation M₁ ` →gm ` M₂ := graded_hom M₁ M₂

abbreviation deg [unfold 5] := @graded_hom.d
postfix ` ↘`:max := graded_hom.fn' -- there is probably a better character for this? Maybe ↷?

definition graded_hom_fn [reducible] [unfold 5] [coercion] (f : M₁ →gm M₂) (i : I) : M₁ i →lm M₂ (deg f i) :=
f ↘ idp

definition graded_hom_fn_out [reducible] [unfold 5] (f : M₁ →gm M₂) (i : I) : M₁ ((deg f)⁻¹ i) →lm M₂ i :=
f ↘ (to_right_inv (deg f) i)

infix ` ← `:101 := graded_hom_fn_out -- todo: change notation

definition graded_hom.mk [constructor] (d : I ≃ I)
  (fn : Πi, M₁ i →lm M₂ (d i)) : M₁ →gm M₂ :=
graded_hom.mk' d (λi j p, homomorphism_of_eq (ap M₂ p) ∘lm fn i)

definition graded_hom.mk_out [constructor] (d : I ≃ I)
  (fn : Πi, M₁ (d⁻¹ i) →lm M₂ i) : M₁ →gm M₂ :=
graded_hom.mk' d (λi j p, fn j ∘lm homomorphism_of_eq (ap M₁ (eq_inv_of_eq p)))

definition graded_hom.mk_out_in [constructor] (d₁ : I ≃ I) (d₂ : I ≃ I)
  (fn : Πi, M₁ (d₁ i) →lm M₂ (d₂ i)) : M₁ →gm M₂ :=
graded_hom.mk' (d₁⁻¹ᵉ ⬝e d₂) (λi j p, homomorphism_of_eq (ap M₂ p) ∘lm fn (d₁⁻¹ᵉ i) ∘lm
  homomorphism_of_eq (ap M₁ (to_right_inv d₁ i)⁻¹))

definition graded_hom_eq_transport (f : M₁ →gm M₂) {i j : I} (p : deg f i = j) (m : M₁ i) :
  f ↘ p m = transport M₂ p (f i m) :=
by induction p; reflexivity

definition graded_hom_mk_refl (d : I ≃ I)
  (fn : Πi, M₁ i →lm M₂ (d i)) {i : I} (m : M₁ i) : graded_hom.mk d fn i m = fn i m :=
by reflexivity

definition graded_hom_eq_zero {f : M₁ →gm M₂} {i j k : I} {q : deg f i = j} {p : deg f i = k}
  (m : M₁ i) (r : f ↘ q m = 0) : f ↘ p m = 0 :=
have f ↘ p m = transport M₂ (q⁻¹ ⬝ p) (f ↘ q m), begin induction p, induction q, reflexivity end,
this ⬝ ap (transport M₂ (q⁻¹ ⬝ p)) r ⬝ tr_eq_of_pathover (apd (λi, 0) (q⁻¹ ⬝ p))

variables {f' : M₂ →gm M₃} {f g h : M₁ →gm M₂}

definition graded_hom_compose [constructor] (f' : M₂ →gm M₃) (f : M₁ →gm M₂) : M₁ →gm M₃ :=
graded_hom.mk (deg f ⬝e deg f') (λi, f' (deg f i) ∘lm f i)

infixr ` ∘gm `:75 := graded_hom_compose

definition graded_hom_compose_fn (f' : M₂ →gm M₃) (f : M₁ →gm M₂) (i : I) (m : M₁ i) :
  (f' ∘gm f) i m = f' (deg f i) (f i m) :=
proof idp qed

variable (M)
definition graded_hom_id [constructor] [refl] : M →gm M :=
graded_hom.mk erfl (λi, lmid)
variable {M}
abbreviation gmid [constructor] := graded_hom_id M

definition gm_constant [constructor] (M₁ M₂ : graded_module R I) (d : I ≃ I) : M₁ →gm M₂ :=
graded_hom.mk' d (gmd_constant d M₁ M₂)

definition is_surjective_graded_hom_compose ⦃x z⦄
  (f' : M₂ →gm M₃) (f : M₁ →gm M₂) (p : deg f' (deg f x) = z)
  (H' : Π⦃y⦄ (q : deg f' y = z), is_surjective (f' ↘ q))
  (H : Π⦃y⦄ (q : deg f x = y), is_surjective (f ↘ q)) : is_surjective ((f' ∘gm f) ↘ p) :=
begin
  induction p,
  apply is_surjective_compose (f' (deg f x)) (f x),
  apply H', apply H
end

structure graded_iso (M₁ M₂ : graded_module R I) : Type :=
mk' :: (to_hom : M₁ →gm M₂)
       (is_equiv_to_hom : Π⦃i j⦄ (p : deg to_hom i = j), is_equiv (to_hom ↘ p))

infix ` ≃gm `:25 := graded_iso
attribute graded_iso.to_hom [coercion]
attribute graded_iso._trans_of_to_hom [unfold 5]

definition is_equiv_graded_iso [instance] [priority 1010] (φ : M₁ ≃gm M₂) (i : I) :
  is_equiv (φ i) :=
graded_iso.is_equiv_to_hom φ idp

definition isomorphism_of_graded_iso' [constructor] (φ : M₁ ≃gm M₂) {i j : I} (p : deg φ i = j) :
  M₁ i ≃lm M₂ j :=
isomorphism.mk (φ ↘ p) !graded_iso.is_equiv_to_hom

definition isomorphism_of_graded_iso [constructor] (φ : M₁ ≃gm M₂) (i : I) :
  M₁ i ≃lm M₂ (deg φ i) :=
isomorphism.mk (φ i) _

definition isomorphism_of_graded_iso_out [constructor] (φ : M₁ ≃gm M₂) (i : I) :
  M₁ ((deg φ)⁻¹ i) ≃lm M₂ i :=
isomorphism_of_graded_iso' φ !to_right_inv

protected definition graded_iso.mk [constructor] (d : I ≃ I) (φ : Πi, M₁ i ≃lm M₂ (d i)) :
  M₁ ≃gm M₂ :=
begin
  apply graded_iso.mk' (graded_hom.mk d φ),
  intro i j p, induction p,
  exact to_is_equiv (equiv_of_isomorphism (φ i)),
end

protected definition graded_iso.mk_out [constructor] (d : I ≃ I) (φ : Πi, M₁ (d⁻¹ i) ≃lm M₂ i) :
  M₁ ≃gm M₂ :=
begin
  apply graded_iso.mk' (graded_hom.mk_out d φ),
  intro i j p, esimp,
  exact @is_equiv_compose _ _ _ _ _ !is_equiv_cast _,
end

definition graded_iso_of_eq [constructor] {M₁ M₂ : graded_module R I} (p : M₁ ~ M₂)
  : M₁ ≃gm M₂ :=
graded_iso.mk erfl (λi, isomorphism_of_eq (p i))

-- definition to_gminv [constructor] (φ : M₁ ≃gm M₂) : M₂ →gm M₁ :=
-- graded_hom.mk_out (deg φ)⁻¹ᵉ
--   abstract begin
--     intro i, apply isomorphism.to_hom, symmetry,
--     apply isomorphism_of_graded_iso φ
--   end end

variable (M)
definition graded_iso.refl [refl] [constructor] : M ≃gm M :=
graded_iso.mk equiv.rfl (λi, isomorphism.rfl)
variable {M}

definition graded_iso.rfl [refl] [constructor] : M ≃gm M := graded_iso.refl M

definition graded_iso.symm [symm] [constructor] (φ : M₁ ≃gm M₂) : M₂ ≃gm M₁ :=
graded_iso.mk_out (deg φ)⁻¹ᵉ (λi, (isomorphism_of_graded_iso φ i)⁻¹ˡᵐ)

definition graded_iso.trans [trans] [constructor] (φ : M₁ ≃gm M₂) (ψ : M₂ ≃gm M₃) : M₁ ≃gm M₃ :=
graded_iso.mk (deg φ ⬝e deg ψ)
  (λi, isomorphism_of_graded_iso φ i ⬝lm isomorphism_of_graded_iso ψ (deg φ i))

definition graded_iso.eq_trans [trans] [constructor]
   {M₁ M₂ M₃ : graded_module R I} (φ : M₁ ~ M₂) (ψ : M₂ ≃gm M₃) : M₁ ≃gm M₃ :=
proof graded_iso.trans (graded_iso_of_eq φ) ψ qed

definition graded_iso.trans_eq [trans] [constructor]
  {M₁ M₂ M₃ : graded_module R I} (φ : M₁ ≃gm M₂) (ψ : M₂ ~ M₃) : M₁ ≃gm M₃ :=
graded_iso.trans φ (graded_iso_of_eq ψ)

postfix `⁻¹ᵉᵍᵐ`:(max + 1) := graded_iso.symm
infixl ` ⬝egm `:75 := graded_iso.trans
infixl ` ⬝egmp `:75 := graded_iso.trans_eq
infixl ` ⬝epgm `:75 := graded_iso.eq_trans

definition graded_hom_of_eq [constructor] {M₁ M₂ : graded_module R I} (p : M₁ ~ M₂) : M₁ →gm M₂ :=
proof graded_iso_of_eq p qed

definition fooff {I : Set} (P : I → Type) {i j : I} (M : P i) (N : P j) := unit
notation M ` ==[`:50 P:0 `] `:0 N:50 := fooff P M N

definition graded_homotopy (f g : M₁ →gm M₂) : Type :=
Π⦃i j k⦄ (p : deg f i = j) (q : deg g i = k) (m : M₁ i), f ↘ p m ==[λi, M₂ i] g ↘ q m
-- mk' :: (hd : deg f ~ deg g)
--        (hfn : Π⦃i j : I⦄ (pf : deg f i = j) (pg : deg g i = j), f ↘ pf ~ g ↘ pg)

infix ` ~gm `:50 := graded_homotopy

-- definition graded_homotopy.mk2 (hd : deg f ~ deg g) (hfn : Πi m, f i m =[hd i] g i m) : f ~gm g :=
-- graded_homotopy.mk' hd
--   begin
--     intro i j pf pg m, induction (is_set.elim (hd i ⬝ pg) pf), induction pg, esimp,
--     exact graded_hom_eq_transport f (hd i) m ⬝ tr_eq_of_pathover (hfn i m),
--   end

definition graded_homotopy.mk (h : Πi m, f i m ==[λi, M₂ i] g i m) : f ~gm g :=
begin
  intros i j k p q m, induction q, induction p, constructor --exact h i m
end

-- definition graded_hom_compose_out {d₁ d₂ : I ≃ I} (f₂ : Πi, M₂ i →lm M₃ (d₂ i))
--   (f₁ : Πi, M₁ (d₁⁻¹ i) →lm M₂ i) : graded_hom.mk d₂ f₂ ∘gm graded_hom.mk_out d₁ f₁ ~gm
--   graded_hom.mk_out_in d₁⁻¹ᵉ d₂ _ :=
-- _

definition graded_hom_out_in_compose_out {d₁ d₂ d₃ : I ≃ I} (f₂ : Πi, M₂ (d₂ i) →lm M₃ (d₃ i))
  (f₁ : Πi, M₁ (d₁⁻¹ i) →lm M₂ i) : graded_hom.mk_out_in d₂ d₃ f₂ ∘gm graded_hom.mk_out d₁ f₁ ~gm
  graded_hom.mk_out_in (d₂ ⬝e d₁⁻¹ᵉ) d₃ (λi, f₂ i ∘lm (f₁ (d₂ i))) :=
begin
  apply graded_homotopy.mk, intro i m, exact sorry
end

definition graded_hom_out_in_rfl {d₁ d₂ : I ≃ I} (f : Πi, M₁ i →lm M₂ (d₂ i))
  (p : Πi, d₁ i = i) :
  graded_hom.mk_out_in d₁ d₂ (λi, sorry) ~gm graded_hom.mk d₂ f :=
begin
  apply graded_homotopy.mk, intro i m, exact sorry
end

definition graded_homotopy.trans (h₁ : f ~gm g) (h₂ : g ~gm h) : f ~gm h :=
begin
  exact sorry
end

-- postfix `⁻¹ᵍᵐ`:(max + 1) := graded_iso.symm
infixl ` ⬝gm `:75 := graded_homotopy.trans
-- infixl ` ⬝gmp `:75 := graded_iso.trans_eq
-- infixl ` ⬝pgm `:75 := graded_iso.eq_trans


-- definition graded_homotopy_of_deg (d : I ≃ I) (f g : graded_hom_of_deg d M₁ M₂) : Type :=
-- Π⦃i j : I⦄ (p : d i = j), f p ~ g p

-- notation f ` ~[`:50 d:0 `] `:0 g:50 := graded_homotopy_of_deg d f g

-- variables {d : I ≃ I} {f₁ f₂ : graded_hom_of_deg d M₁ M₂}

-- definition graded_homotopy_of_deg.mk [constructor] (h : Πi, f₁ (idpath (d i)) ~ f₂ (idpath (d i))) :
--   f₁ ~[d] f₂ :=
-- begin
--   intro i j p, induction p, exact h i
-- end

-- definition graded_homotopy.mk_out [constructor] {M₁ M₂ : graded_module R I} (d : I ≃ I)
--   (fn : Πi, M₁ (d⁻¹ i) →lm M₂ i) : M₁ →gm M₂ :=
-- graded_hom.mk' d (λi j p, fn j ∘lm homomorphism_of_eq (ap M₁ (eq_inv_of_eq p)))
-- definition is_gconstant (f : M₁ →gm M₂) : Type :=
-- f↘ ~[deg f] gmd0

definition compose_constant (f' : M₂ →gm M₃) (f : M₁ →gm M₂) : Type :=
Π⦃i j k : I⦄ (p : deg f i = j) (q : deg f' j = k) (m : M₁ i), f' ↘ q (f ↘ p m) = 0

definition compose_constant.mk (h : Πi m, f' (deg f i) (f i m) = 0) : compose_constant f' f :=
by intros; induction p; induction q; exact h i m

definition compose_constant.elim (h : compose_constant f' f) (i : I) (m : M₁ i) : f' (deg f i) (f i m) = 0 :=
h idp idp m

definition is_gconstant (f : M₁ →gm M₂) : Type :=
Π⦃i j : I⦄ (p : deg f i = j) (m : M₁ i), f ↘ p m = 0

definition is_gconstant.mk (h : Πi m, f i m = 0) : is_gconstant f :=
by intros; induction p; exact h i m

definition is_gconstant.elim (h : is_gconstant f) (i : I) (m : M₁ i) : f i m = 0 :=
h idp m

/- direct sum of graded R-modules -/

variables {J : Set} (N : graded_module R J)
definition dirsum' : AddAbGroup :=
group.dirsum (λj, AddAbGroup_of_LeftModule (N j))
variable {N}
definition dirsum_smul [constructor] (r : R) : dirsum' N →a dirsum' N :=
dirsum_functor (λi, smul_homomorphism (N i) r)

definition dirsum_smul_right_distrib (r s : R) (n : dirsum' N) :
  dirsum_smul (r + s) n = dirsum_smul r n + dirsum_smul s n :=
begin
  refine dirsum_functor_homotopy _ n ⬝ !dirsum_functor_add⁻¹,
  intro i ni, exact to_smul_right_distrib r s ni
end

definition dirsum_mul_smul' (r s : R) (n : dirsum' N) :
  dirsum_smul (r * s) n = (dirsum_smul r ∘a dirsum_smul s) n :=
begin
  refine dirsum_functor_homotopy _ n ⬝ (dirsum_functor_compose _ _ n)⁻¹ᵖ,
  intro i ni, exact to_mul_smul r s ni
end

definition dirsum_mul_smul (r s : R) (n : dirsum' N) :
  dirsum_smul (r * s) n = dirsum_smul r (dirsum_smul s n) :=
proof dirsum_mul_smul' r s n qed

definition dirsum_one_smul (n : dirsum' N) : dirsum_smul 1 n = n :=
begin
  refine dirsum_functor_homotopy _ n ⬝ !dirsum_functor_gid,
  intro i ni, exact to_one_smul ni
end

definition dirsum : LeftModule R :=
LeftModule_of_AddAbGroup (dirsum' N) (λr n, dirsum_smul r n)
  (λr, homomorphism.addstruct (dirsum_smul r))
  dirsum_smul_right_distrib
  dirsum_mul_smul
  dirsum_one_smul

/- graded variants of left-module constructions -/

definition graded_submodule [constructor] (S : Πi, submodule_rel (M i)) : graded_module R I :=
λi, submodule (S i)

definition graded_submodule_incl [constructor] (S : Πi, submodule_rel (M i)) :
  graded_submodule S →gm M :=
graded_hom.mk erfl (λi, submodule_incl (S i))

definition graded_hom_lift [constructor] {S : Πi, submodule_rel (M₂ i)}
  (φ : M₁ →gm M₂)
  (h : Π(i : I) (m : M₁ i), S (deg φ i) (φ i m)) : M₁ →gm graded_submodule S :=
graded_hom.mk (deg φ) (λi, hom_lift (φ i) (h i))

definition graded_image (f : M₁ →gm M₂) : graded_module R I :=
λi, image_module (f ← i)

definition graded_image_lift [constructor] (f : M₁ →gm M₂) : M₁ →gm graded_image f :=
graded_hom.mk_out (deg f) (λi, image_lift (f ← i))

definition graded_image_elim [constructor] {f : M₁ →gm M₂} (g : M₁ →gm M₃)
  (h : Π⦃i m⦄, f i m = 0 → g i m = 0) :
  graded_image f →gm M₃ :=
begin
  apply graded_hom.mk_out_in (deg f) (deg g),
  intro i,
  apply image_elim (g ↘ (ap (deg g) (to_left_inv (deg f) i))),
  intro m p,
  refine graded_hom_eq_zero m (h _),
  exact graded_hom_eq_zero m p
end

definition is_surjective_graded_image_lift ⦃x y⦄ (f : M₁ →gm M₂)
  (p : deg f x = y) : is_surjective (graded_image_lift f ↘ p) :=
begin
  exact sorry
end

definition graded_image' (f : M₁ →gm M₂) : graded_module R I :=
λi, image_module (f i)

definition graded_image'_lift [constructor] (f : M₁ →gm M₂) : M₁ →gm graded_image' f :=
graded_hom.mk erfl (λi, image_lift (f i))

definition graded_image'_elim [constructor] {f : M₁ →gm M₂} (g : M₁ →gm M₃)
  (h : Π⦃i m⦄, f i m = 0 → g i m = 0) :
  graded_image' f →gm M₃ :=
begin
  apply graded_hom.mk (deg g),
  intro i,
  apply image_elim (g i),
  intro m p, exact h p
end

theorem graded_image'_elim_compute {f : M₁ →gm M₂} {g : M₁ →gm M₃}
  (h : Π⦃i m⦄, f i m = 0 → g i m = 0) :
  graded_image'_elim g h ∘gm graded_image'_lift f ~gm g :=
begin
  apply graded_homotopy.mk,
  intro i m, exact sorry --reflexivity
end

theorem graded_image_elim_compute {f : M₁ →gm M₂} {g : M₁ →gm M₃}
  (h : Π⦃i m⦄, f i m = 0 → g i m = 0) :
  graded_image_elim g h ∘gm graded_image_lift f ~gm g :=
begin
  refine _ ⬝gm graded_image'_elim_compute h,
  esimp, exact sorry
  -- refine graded_hom_out_in_compose_out _ _ ⬝gm _, exact sorry
  -- -- apply graded_homotopy.mk,
  -- -- intro i m,
end
variables {α β : I ≃ I}
definition gen_image (f : M₁ →gm M₂) (p : Πi, deg f (α i) = β i) : graded_module R I :=
λi, image_module (f ↘ (p i))

definition gen_image_lift [constructor] (f : M₁ →gm M₂) (p : Πi, deg f (α i) = β i) : M₁ →gm gen_image f p :=
graded_hom.mk_out α⁻¹ᵉ (λi, image_lift (f ↘ (p i)))

definition gen_image_elim [constructor] {f : M₁ →gm M₂} (p : Πi, deg f (α i) = β i) (g : M₁ →gm M₃)
  (h : Π⦃i m⦄, f i m = 0 → g i m = 0) :
  gen_image f p →gm M₃ :=
begin
  apply graded_hom.mk_out_in α⁻¹ᵉ (deg g),
  intro i,
  apply image_elim (g ↘ (ap (deg g) (to_right_inv α i))),
  intro m p,
  refine graded_hom_eq_zero m (h _),
  exact graded_hom_eq_zero m p
end

theorem gen_image_elim_compute {f : M₁ →gm M₂} {p : deg f ∘ α ~ β} {g : M₁ →gm M₃}
  (h : Π⦃i m⦄, f i m = 0 → g i m = 0) :
  gen_image_elim p g h ∘gm gen_image_lift f p ~gm g :=
begin
  -- induction β with β βe, esimp at *, induction p using homotopy.rec_on_idp,
  assert q : β ⬝e (deg f)⁻¹ᵉ = α,
  { apply equiv_eq, intro i, apply inv_eq_of_eq, exact (p i)⁻¹ },
  induction q,
  -- unfold [gen_image_elim, gen_image_lift],

  -- induction (is_prop.elim (λi, to_right_inv (deg f) (β i)) p),
  -- apply graded_homotopy.mk,
  -- intro i m, reflexivity
  exact sorry
end

definition graded_kernel (f : M₁ →gm M₂) : graded_module R I :=
λi, kernel_module (f i)

definition graded_quotient (S : Πi, submodule_rel (M i)) : graded_module R I :=
λi, quotient_module (S i)

definition graded_quotient_map [constructor] (S : Πi, submodule_rel (M i)) :
  M →gm graded_quotient S :=
graded_hom.mk erfl (λi, quotient_map (S i))

definition graded_homology (g : M₂ →gm M₃) (f : M₁ →gm M₂) : graded_module R I :=
λi, homology (g i) (f ← i)

definition graded_homology_intro [constructor] (g : M₂ →gm M₃) (f : M₁ →gm M₂) :
  graded_kernel g →gm graded_homology g f :=
graded_quotient_map _

definition graded_homology_elim {g : M₂ →gm M₃} {f : M₁ →gm M₂} (h : M₂ →gm M)
  (H : compose_constant h f) : graded_homology g f →gm M :=
graded_hom.mk (deg h) (λi, homology_elim (h i) (H _ _))


/- exact couples -/

definition is_exact_gmod (f : M₁ →gm M₂) (f' : M₂ →gm M₃) : Type :=
Π⦃i j k⦄ (p : deg f i = j) (q : deg f' j = k), is_exact_mod (f ↘ p) (f' ↘ q)

definition is_exact_gmod.mk {f : M₁ →gm M₂} {f' : M₂ →gm M₃}
  (h₁ : Π⦃i⦄ (m : M₁ i), f' (deg f i) (f i m) = 0)
  (h₂ : Π⦃i⦄ (m : M₂ (deg f i)), f' (deg f i) m = 0 → image (f i) m) : is_exact_gmod f f' :=
begin intro i j k p q; induction p; induction q; split, apply h₁, apply h₂ end

definition gmod_im_in_ker (h : is_exact_gmod f f') : compose_constant f' f :=
λi j k p q, is_exact.im_in_ker (h p q)

-- structure exact_couple (M₁ M₂ : graded_module R I) : Type :=
--   (i : M₁ →gm M₁) (j : M₁ →gm M₂) (k : M₂ →gm M₁)
--   (exact_ij : is_exact_gmod i j)
--   (exact_jk : is_exact_gmod j k)
--   (exact_ki : is_exact_gmod k i)

end left_module

namespace left_module

  structure exact_couple (R : Ring) (I : Set) : Type :=
    (D E : graded_module R I)
    (i : D →gm D) (j : D →gm E) (k : E →gm D)
    (ij : is_exact_gmod i j)
    (jk : is_exact_gmod j k)
    (ki : is_exact_gmod k i)

  namespace derived_couple
  section
  open exact_couple

  parameters {R : Ring} {I : Set} (X : exact_couple R I)
  local abbreviation D := D X
  local abbreviation E := E X
  local abbreviation i := i X
  local abbreviation j := j X
  local abbreviation k := k X
  local abbreviation ij := ij X
  local abbreviation jk := jk X
  local abbreviation ki := ki X

  definition d : E →gm E := j ∘gm k
  definition D' : graded_module R I := graded_image i
  definition E' : graded_module R I := graded_homology d d

  definition is_contr_E' {x : I} (H : is_contr (E x)) : is_contr (E' x) :=
  !is_contr_homology

  definition is_contr_D' {x : I} (H : is_contr (D x)) : is_contr (D' x) :=
  !is_contr_image_module

  definition i' : D' →gm D' :=
  graded_image_lift i ∘gm graded_submodule_incl _
  -- degree i + 0

  lemma is_surjective_i' {x y : I} (p : deg i' x = y)
    (H : Π⦃z⦄ (q : deg i z = x), is_surjective (i ↘ q)) : is_surjective (i' ↘ p) :=
  begin
    apply is_surjective_graded_hom_compose,
    { intro y q, apply is_surjective_graded_image_lift },
    { intro y q, apply is_surjective_of_is_equiv,
      induction q,
      exact to_is_equiv (equiv_of_isomorphism (image_module_isomorphism (i ← x) (H _)))
      }
  end

  lemma j_lemma1 ⦃x : I⦄ (m : D x) : d ((deg j) x) (j x m) = 0 :=
  begin
    rewrite [graded_hom_compose_fn,↑d,graded_hom_compose_fn],
    refine ap (graded_hom_fn j (deg k (deg j x))) _ ⬝
      !to_respect_zero,
    exact compose_constant.elim (gmod_im_in_ker (jk)) x m
  end

  lemma j_lemma2 : Π⦃x : I⦄ ⦃m : D x⦄ (p : i x m = 0),
    (graded_quotient_map _ ∘gm graded_hom_lift j j_lemma1) x m = 0 :> E' _ :=
  begin
    have Π⦃x y : I⦄ (q : deg k x = y) (r : deg d x = deg j y)
      (s : ap (deg j) q = r) ⦃m : D y⦄ (p : i y m = 0), image (d ↘ r) (j y m),
    begin
      intros, induction s, induction q,
      note m_in_im_k := is_exact.ker_in_im (ki idp _) _ p,
      induction m_in_im_k with e q,
      induction q,
      apply image.mk e idp
    end,
    have Π⦃x : I⦄ ⦃m : D x⦄ (p : i x m = 0), image (d ← (deg j x)) (j x m),
    begin
      intros,
      refine this _ _ _ p,
      exact to_right_inv (deg k) _ ⬝ to_left_inv (deg j) x,
      apply is_set.elim
      -- rewrite [ap_con, -adj],
    end,
    intros,
    rewrite [graded_hom_compose_fn],
    exact quotient_map_eq_zero _ (this p)
  end

  definition j' : D' →gm E' :=
  graded_image_elim (graded_homology_intro d d ∘gm graded_hom_lift j j_lemma1) j_lemma2
  -- degree deg j - deg i

  theorem k_lemma1 ⦃x : I⦄ (m : E x) : image (i ← (deg k x)) (k x m) :=
  begin
    exact sorry
  end

  theorem k_lemma2 : compose_constant (graded_hom_lift k k_lemma1 : E →gm D') d :=
  begin
    --   apply compose_constant.mk, intro x m,
    --   rewrite [graded_hom_compose_fn],
    --   refine ap (graded_hom_fn (graded_image_lift i) (deg k (deg d x))) _ ⬝ !to_respect_zero,
    --   exact compose_constant.elim (gmod_im_in_ker jk) (deg k x) (k x m)
    exact sorry
  end

  definition k' : E' →gm D' :=
  graded_homology_elim (graded_hom_lift k k_lemma1) k_lemma2

  definition deg_i' : deg i' ~ deg i := by reflexivity
  definition deg_j' : deg j' ~ deg j ∘ (deg i)⁻¹ := by reflexivity
  definition deg_k' : deg k' ~ deg k := by reflexivity

  theorem i'j' : is_exact_gmod i' j' :=
  begin
    apply is_exact_gmod.mk,
    { intro x, refine total_image.rec _, intro m, exact sorry
      -- exact calc
      --   j' (deg i' x) (i' x ⟨(i ← x) m, image.mk m idp⟩)
      --       = j' (deg i' x) (graded_image_lift i x ((i ← x) m)) : idp
      --   ... = graded_homology_intro d d (deg j ((deg i)⁻¹ᵉ (deg i x)))
      --           (graded_hom_lift j j_lemma1 ((deg i)⁻¹ᵉ (deg i x))
      --           (i ↘ (!to_right_inv ⬝ !to_left_inv⁻¹) m)) : _
      --   ... = graded_homology_intro d d (deg j ((deg i)⁻¹ᵉ (deg i x)))
      --           (graded_hom_lift j j_lemma1 ((deg i)⁻¹ᵉ (deg i x))
      --           (i ↘ (!to_right_inv ⬝ !to_left_inv⁻¹) m)) : _
      --   ... = 0 : _
      },
    { exact sorry }
  end

  theorem j'k' : is_exact_gmod j' k' :=
  begin
    apply is_exact_gmod.mk,
    { exact sorry },
    { exact sorry }
  end

  theorem k'i' : is_exact_gmod k' i' :=
  begin
    apply is_exact_gmod.mk,
    { intro x m, exact sorry },
    { exact sorry }
  end

  end
  end derived_couple

  section
  open derived_couple exact_couple

  definition derived_couple [constructor] {R : Ring} {I : Set}
    (X : exact_couple R I) : exact_couple R I :=
  ⦃exact_couple, D := D' X, E := E' X, i := i' X, j := j' X, k := k' X,
    ij := i'j' X, jk := j'k' X, ki := k'i' X⦄

  parameters {R : Ring} {I : Set} (X : exact_couple R I) (B B' : I → ℕ)
    (Dub : Π⦃x y⦄ ⦃s : ℕ⦄, (deg (i X))^[s] x = y → B x ≤ s → is_contr (D X y))
    (Eub : Π⦃x y⦄ ⦃s : ℕ⦄, (deg (k X))⁻¹ (iterate (deg (i X)) s ((deg (j X))⁻¹ x)) = y →
           B x ≤ s → is_contr (E X y))
    (Dlb : Π⦃x y z⦄ ⦃s : ℕ⦄ (p : deg (i X) x = y),
    iterate (deg (i X)) s y = z → B' z ≤ s → is_surjective (i X ↘ p))
    (Elb : Π⦃x y⦄ ⦃s : ℕ⦄, deg (j X) (iterate (deg (i X))⁻¹ᵉ s (deg (k X) x)) = y → B x ≤ s →
           is_contr (E X y))
    (deg_ik_commute : deg (i X) ∘ deg (k X) ~ deg (k X) ∘ deg (i X))

  definition deg_iterate_ik_commute (n : ℕ) (x : I) :
    (deg (i X))^[n] (deg (k X) x) = deg (k X) ((deg (i X))^[n] x) :=
  iterate_commute _ deg_ik_commute x

  -- we start counting pages at 0, not at 2.
  definition page (r : ℕ) : exact_couple R I :=
  iterate derived_couple r X

  definition is_contr_E (r : ℕ) (x : I) (h : is_contr (E X x)) :
    is_contr (E (page r) x) :=
  by induction r with r IH; exact h; exact is_contr_E' (page r) IH

  definition is_contr_D (r : ℕ) (x : I) (h : is_contr (D X x)) :
    is_contr (D (page r) x) :=
  by induction r with r IH; exact h; exact is_contr_D' (page r) IH

  definition deg_i (r : ℕ) : deg (i (page r)) ~ deg (i X) :=
  begin
    induction r with r IH,
    { reflexivity },
    { exact IH }
  end

  definition deg_k (r : ℕ) : deg (k (page r)) ~ deg (k X) :=
  begin
    induction r with r IH,
    { reflexivity },
    { exact IH }
  end

  definition deg_j (r : ℕ) :
    deg (j (page r)) ~ deg (j X) ∘ iterate (deg (i X))⁻¹ r :=
  begin
    induction r with r IH,
    { reflexivity },
    { refine hwhisker_left (deg (j (page r)))
        (to_inv_homotopy_inv (deg_i r)) ⬝hty _,
      refine hwhisker_right _ IH ⬝hty _,
      apply hwhisker_left, symmetry, apply iterate_succ }
  end

  definition deg_j_inv (r : ℕ) :
    (deg (j (page r)))⁻¹ ~ iterate (deg (i X)) r ∘ (deg (j X))⁻¹ :=
  have H : deg (j (page r)) ~ iterate_equiv (deg (i X))⁻¹ᵉ r ⬝e deg (j X), from deg_j r,
  λx, to_inv_homotopy_to_inv H x ⬝ iterate_inv (deg (i X))⁻¹ᵉ r ((deg (j X))⁻¹ x)

  definition deg_d (r : ℕ) :
    deg (d (page r)) ~ deg (j X) ∘ iterate (deg (i X))⁻¹ r ∘ deg (k X) :=
  compose2 (deg_j r) (deg_k r)

  definition deg_d_inv (r : ℕ) :
    (deg (d (page r)))⁻¹ ~ (deg (k X))⁻¹ ∘ iterate (deg (i X)) r ∘ (deg (j X))⁻¹ :=
  compose2 (to_inv_homotopy_to_inv (deg_k r)) (deg_j_inv r)

  include Elb Eub
  definition Estable {x : I} {r : ℕ} (H : B x ≤ r) :
    E (page (r + 1)) x ≃lm E (page r) x :=
  begin
    change homology (d (page r) x) (d (page r) ← x) ≃lm E (page r) x,
    apply homology_isomorphism: apply is_contr_E,
    exact Eub (deg_d_inv r x)⁻¹ H, exact Elb (deg_d r x)⁻¹ H
  end

  include Dlb
  definition is_surjective_i {x y z : I} {r s : ℕ} (H : B' z ≤ s + r)
    (p : deg (i (page r)) x = y) (q : iterate (deg (i X)) s y = z) :
    is_surjective (i (page r) ↘ p) :=
  begin
    revert x y z s H p q, induction r with r IH: intro x y z s H p q,
    { exact Dlb p q H  },
    { change is_surjective (i' (page r) ↘ p),
      apply is_surjective_i', intro z' q',
      refine IH _ _ _ _ (le.trans H (le_of_eq (succ_add s r)⁻¹)) _ _,
      refine !iterate_succ ⬝ ap ((deg (i X))^[s]) _ ⬝ q,
      exact !deg_i⁻¹ ⬝ p }
  end

  definition Dstable {x : I} {r : ℕ} (H : B' x ≤ r) :
    D (page (r + 1)) x ≃lm D (page r) x :=
  begin
    change image_module (i (page r) ← x) ≃lm D (page r) x,
    refine image_module_isomorphism (i (page r) ← x)
      (is_surjective_i (le.trans H (le_of_eq !zero_add⁻¹)) _ _),
    reflexivity
  end

  definition Einf : graded_module R I :=
  λx, E (page (B x)) x

  definition Dinf : graded_module R I :=
  λx, D (page (B' x)) x

  definition Einfstable {x y : I} {r : ℕ} (Hr : B y ≤ r) (p : x = y) :
    Einf y ≃lm E (page r) x :=
  by symmetry; induction p; induction Hr with r Hr IH; reflexivity; exact Estable Hr ⬝lm IH

  definition Dinfstable {x y : I} {r : ℕ} (Hr : B' y ≤ r) (p : x = y) :
    Dinf y ≃lm D (page r) x :=
  by symmetry; induction p; induction Hr with r Hr IH; reflexivity; exact Dstable Hr ⬝lm IH

  parameters {x : I}

  definition r (n : ℕ) : ℕ :=
  max (max (B x + n + 1) (B ((deg (i X))^[n] x)))
      (max (B' (deg (k X) ((deg (i X))^[n] x)))
           (max (B' (deg (k X) ((deg (i X))^[n+1] x))) (B ((deg (j X))⁻¹ ((deg (i X))^[n] x)))))

  lemma rb0 (n : ℕ) : r n ≥ n + 1 :=
  ge.trans !le_max_left (ge.trans !le_max_left !le_add_left)
  lemma rb1 (n : ℕ) : B x ≤ r n - (n + 1) :=
  le_sub_of_add_le (le.trans !le_max_left !le_max_left)
  lemma rb2 (n : ℕ) : B ((deg (i X))^[n] x) ≤ r n :=
  le.trans !le_max_right !le_max_left
  lemma rb3 (n : ℕ) : B' (deg (k X) ((deg (i X))^[n] x)) ≤ r n :=
  le.trans !le_max_left !le_max_right
  lemma rb4 (n : ℕ) : B' (deg (k X) ((deg (i X))^[n+1] x)) ≤ r n :=
  le.trans (le.trans !le_max_left !le_max_right) !le_max_right
  lemma rb5 (n : ℕ) : B ((deg (j X))⁻¹ ((deg (i X))^[n] x)) ≤ r n :=
  le.trans (le.trans !le_max_right !le_max_right) !le_max_right

  definition Einfdiag : graded_module R ℕ :=
  λn, Einf ((deg (i X))^[n] x)

  definition Dinfdiag : graded_module R ℕ :=
  λn, Dinf (deg (k X) ((deg (i X))^[n] x))

  include deg_ik_commute Dub
  definition short_exact_mod_page_r (n : ℕ) : short_exact_mod
    (E (page (r n)) ((deg (i X))^[n] x))
    (D (page (r n)) (deg (k (page (r n))) ((deg (i X))^[n] x)))
    (D (page (r n)) (deg (i (page (r n))) (deg (k (page (r n))) ((deg (i X))^[n] x)))) :=
  begin
    fapply short_exact_mod_of_is_exact,
    { exact j (page (r n)) ← ((deg (i X))^[n] x) },
    { exact k (page (r n)) ((deg (i X))^[n] x) },
    { exact i (page (r n)) (deg (k (page (r n))) ((deg (i X))^[n] x)) },
    { exact j (page (r n)) _ },
    { apply is_contr_D, refine Dub !deg_j_inv⁻¹ (rb5 n) },
    { apply is_contr_E, refine Elb _ (rb1 n),
      refine ap (deg (j X)) _ ⬝ !deg_j⁻¹,
      refine iterate_sub _ !rb0 _ ⬝ _, apply ap (_^[r n]),
      exact ap (deg (i X)) (!deg_iterate_ik_commute ⬝ !deg_k⁻¹) ⬝ !deg_i⁻¹ },
    { apply jk (page (r n)) },
    { apply ki (page (r n)) },
    { apply ij (page (r n)) }
  end

  definition short_exact_mod_infpage (n : ℕ) :
    short_exact_mod (Einfdiag n) (Dinfdiag n) (Dinfdiag (n+1)) :=
  begin
    refine short_exact_mod_isomorphism _ _ _ (short_exact_mod_page_r n),
    { exact Einfstable !rb2 idp },
    { exact Dinfstable !rb3 !deg_k },
    { exact Dinfstable !rb4 (!deg_i ⬝ ap (deg (i X)) !deg_k ⬝ !deg_ik_commute) }
  end

  definition Dinfdiag0 (bound_zero : B' (deg (k X) x) = 0) : Dinfdiag 0 ≃lm D X (deg (k X) x) :=
  Dinfstable (le_of_eq bound_zero) idp

  definition Dinfdiag_stable {s : ℕ} (h : B (deg (k X) x) ≤ s) : is_contr (Dinfdiag s) :=
  is_contr_D _ _ (Dub !deg_iterate_ik_commute h)

  end


end left_module
