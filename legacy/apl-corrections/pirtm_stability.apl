⍝ pirtm_stability.apl
⍝ Correct finite-gain contraction certificate in pure APL.
⍝ Author: Ahmad Ali Parr · SnapKitty Collective · 2026
⍝
⍝ Mathematical rule:
⍝   A diagonal/operator-gain model is contractive only when spectral radius < 1.
⍝   A claim requiring α ≥ 1 cannot also certify contraction for the same scalar gain.

⎕IO←1

Assert←{⍺←'assertion failed' ⋄ (∧/,⍵):1 ⋄ ⎕←'EDAULC FAIL: ',⍺ ⋄ ⎕SIGNAL 11}

BOB←{
    ⍝ BOB reasoning loop: every step is a boolean proof obligation.
    steps←,⍵
    'empty proof script' Assert 0<≢steps
    'non-boolean proof step' Assert ∧/steps∊0 1
    'proof step rejected' Assert ∧/steps
    1
}

SpectralRadiusDiag←{
    ⍝ Exact for scalar/diagonal gain vectors: ρ(diag(g)) = max |gᵢ|.
    gains←,⍵
    'empty gain vector' Assert 0<≢gains
    ⌈/|gains
}

IsContractive←{
    ⍝ Correct contraction condition.
    1>SpectralRadiusDiag ⍵
}

AceDominantCorrect←{
    ⍝ Correct safe ACE band for a scalar gain α used as a contraction gain.
    ⍝ α may be non-negative, but it must remain strictly below 1.
    alpha←⍵
    (0≤alpha)∧alpha<1
}

AceDominantBroken←{
    ⍝ The public-code pattern being refuted: α ≥ 1.
    ⍵≥1
}

StabilityContradiction←{
    ⍝ A single α cannot satisfy both α<1 and α≥1.
    alpha←⍵
    (alpha<1)∧alpha≥1
}

ContractionCertificate←{
    ⍝ Returns: rho contractive correctACE brokenACE contradiction proofOK
    gains←,⍵
    rho←SpectralRadiusDiag gains
    contractive←rho<1
    alpha←rho
    correctACE←AceDominantCorrect alpha
    brokenACE←AceDominantBroken alpha
    contradiction←StabilityContradiction alpha
    proofOK←BOB (contractive correctACE (~brokenACE) (~contradiction))
    rho contractive correctACE brokenACE contradiction proofOK
}

RejectAlphaGE1AsContraction←{
    ⍝ Positive result: α≥1 is rejected as non-contractive.
    alpha←⍵
    BOB ((AceDominantBroken alpha) (~IsContractive alpha))
}

RunPIRTMStabilityDemo←{
    good←ContractionCertificate 0.6 0.2 0.9
    bad←RejectAlphaGE1AsContraction 1
    good bad
}

