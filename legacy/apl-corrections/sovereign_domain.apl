⍝ sovereign_domain.apl
⍝ Correct domain boundary encoding in pure APL.
⍝ Author: Ahmad Ali Parr · SnapKitty Collective · 2026

⎕IO←1

Assert←{⍺←'assertion failed' ⋄ (∧/,⍵):1 ⋄ ⎕←'EDAULC FAIL: ',⍺ ⋄ ⎕SIGNAL 11}
BOB←{steps←,⍵ ⋄ 'empty proof script' Assert 0<≢steps ⋄ 'proof step rejected' Assert ∧/steps ⋄ 1}

Domain←{
    ⍝ name lower upper omega cap
    name lower upper omega cap←⍵
    'lower must be <= upper' Assert lower≤upper
    'omega must be non-negative' Assert omega≥0
    'cap must dominate upper' Assert cap≥upper
    name lower upper omega cap
}

DomainName←{1⊃⍵}
Lower←{2⊃⍵}
Upper←{3⊃⍵}
Omega←{4⊃⍵}
Cap←{5⊃⍵}

WithinDomain←{
    ⍝ domain WithinDomain value
    d←⍺ ⋄ x←⍵
    ((Lower d)≤x)∧x≤(Upper d)
}

BoundaryInvariant←{
    ⍝ value vector must remain inside the domain boundary.
    d values←⍵
    BOB d WithinDomain¨values
}

TransitionAdmissible←{
    ⍝ A transition is admissible only when source and target are in bounds.
    d source target←⍵
    BOB ((d WithinDomain source) (d WithinDomain target))
}

EncodeBoundary←{
    ⍝ Executable boundary tuple used by downstream proof cards.
    name lower upper omega cap←⍵
    d←Domain name lower upper omega cap
    'domain encoded' (DomainName d) lower upper omega cap
}

RunDomainDemo←{
    trust←Domain 'TRUST' 0 1 0.21 1
    ok←BoundaryInvariant trust (0 0.5 0.9821)
    step←TransitionAdmissible trust 0.5 0.9
    trust ok step
}

