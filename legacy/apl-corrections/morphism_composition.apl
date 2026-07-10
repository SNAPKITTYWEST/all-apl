⍝ morphism_composition.apl
⍝ Correct f∘g order in pure APL.
⍝ Author: Ahmad Ali Parr · SnapKitty Collective · 2026

⎕IO←1

Assert←{⍺←'assertion failed' ⋄ (∧/,⍵):1 ⋄ ⎕←'EDAULC FAIL: ',⍺ ⋄ ⎕SIGNAL 11}
BOB←{steps←,⍵ ⋄ 'empty proof script' Assert 0<≢steps ⋄ 'proof step rejected' Assert ∧/steps ⋄ 1}

Compose←{
    ⍝ Dyadic operator:
    ⍝   (f Compose g) x = f(g(x))
    ⍺⍺ ⍵⍵ ⍵
}

Inc←{1+⍵}
Double←{2×⍵}
Square←{⍵*2}

CompositionOrderCertificate←{
    x←⍵
    fg←(Double Compose Inc) x    ⍝ 2×(x+1)
    gf←(Inc Compose Double) x    ⍝ (2×x)+1
    distinct←fg≠gf
    expectedFG←fg=2×x+1
    expectedGF←gf=1+2×x
    proofOK←BOB (distinct expectedFG expectedGF)
    x fg gf distinct proofOK
}

AssociativityCertificate←{
    x←⍵
    lhs←(Square Compose (Double Compose Inc)) x
    rhs←((Square Compose Double) Compose Inc) x
    proofOK←BOB lhs=rhs
    x lhs rhs proofOK
}

RunMorphismDemo←{
    order←CompositionOrderCertificate 3
    assoc←AssociativityCertificate 3
    order assoc
}

