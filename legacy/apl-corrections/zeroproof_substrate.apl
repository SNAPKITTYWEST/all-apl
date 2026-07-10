⍝ zeroproof_substrate.apl
⍝ Ahmad's Zeroproof substrate in pure APL.
⍝ Refutes literal proof hashes and tautological factorization claims.
⍝ Author: Ahmad Ali Parr · SnapKitty Collective · 2026

⎕IO←1

Assert←{⍺←'assertion failed' ⋄ (∧/,⍵):1 ⋄ ⎕←'EDAULC FAIL: ',⍺ ⋄ ⎕SIGNAL 11}

BOB←{
    steps←,⍵
    'empty proof script' Assert 0<≢steps
    'non-boolean proof step' Assert ∧/steps∊0 1
    'proof step rejected' Assert ∧/steps
    1
}

HexChars←'0123456789abcdefABCDEF'

IsSha256←{
    ⍝ Structural SHA-256 digest validator: exactly 64 hex chars.
    s←,⍵
    (64=≢s)∧∧/s∊HexChars
}

RejectLiteralProofHash←{
    ⍝ Rejects placeholder strings such as LEAN_PROOF_HASH_108_CORE.
    ~IsSha256 ⍵
}

Divisors←{
    n←⍵
    (⍳n)/⍨0=(⍳n)|n
}

IsPrime←{
    n←⍵
    (n>1)∧2=≢Divisors n
}

SmallestPrimeFactor←{
    n←⍵
    ps←(⍳n)/⍨(IsPrime¨⍳n)∧0=(⍳n)|n
    'no prime factor' Assert 0<≢ps
    ⊃ps
}

FactorList←{
    ⍵=1:⍬
    p←SmallestPrimeFactor ⍵
    p,∇ ⍵÷p
}

FactorProductOK←{
    n←⍵
    n=1:1
    n=×/FactorList n
}

FactorSortedOK←{
    f←FactorList ⍵
    f≡f[⍋f]
}

FactorizationCertificate←{
    ⍝ Real executable factorization witness.
    n←⍵
    factors←FactorList n
    productOK←FactorProductOK n
    sortedOK←FactorSortedOK n
    allPrime←∧/IsPrime¨factors
    proofOK←BOB (productOK sortedOK allPrime)
    n factors productOK sortedOK allPrime proofOK
}

RejectTautologyFactorUnique←{
    ⍝ The proposition p=n -> p=n is valid but proves no factorization fact.
    proposition←⍵
    proposition≡'p=n->p=n':1
    proposition≡'∀p,p=n→p=n':1
    0
}

ZeroproofCheck←{
    ⍝ Input: hash n proposition
    hash n proposition←⍵
    hashRejected←RejectLiteralProofHash hash
    fact←FactorizationCertificate n
    tautRejected←RejectTautologyFactorUnique proposition
    proofOK←BOB (hashRejected (6⊃fact) tautRejected)
    hashRejected fact tautRejected proofOK
}

RunZeroproofDemo←{
    ZeroproofCheck 'LEAN_PROOF_HASH_108_CORE' 108 'p=n->p=n'
}

