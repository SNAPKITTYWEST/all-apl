⍝ transforms.apl
⍝ APL Transform Console — Module 8
⍝ Author: Ahmad Ali Parr · SnapKitty Collective · 2026
⍝
⍝ Symbolic transforms for the INTERCOL UI APL console.
⍝ All outputs are table/grid readable — feeds the Swift UI via JSON bridge.
⍝
⍝ Transforms:
⍝   1. Fibonacci contraction (phinary basis)
⍝   2. Phinary entropy mapping
⍝   3. Trust-vector reduction
⍝   4. Semantic agreement fold
⍝   5. 13-node resonance matrix

⎕IO←1
⎕PP←6

Assert←{⍺←'assertion failed' ⋄ (∧/,⍵):1 ⋄ ⎕←'EDAULC FAIL: ',⍺ ⋄ ⎕SIGNAL 11}
BOB←{steps←,⍵ ⋄ 'empty proof script' Assert 0<≢steps ⋄ 'proof step rejected' Assert ∧/steps ⋄ 1}

PHI←(1+5*0.5)÷2   ⍝ Golden ratio φ = 1.6180...

⍝ ── Transform 1: Fibonacci Contraction ──────────────────────────────────────

FibSeq←{
    ⍝ Generate N Fibonacci numbers — phinary basis
    N←⍵
    'need at least 2 terms' Assert N≥2
    seq←1 1
    {seq,←+/¯2↑seq}⍣(N-2)⍬
    N↑seq
}

PhinContraction←{
    ⍝ Contract a value toward phinary fixed point
    ⍝ Iterated: x_n+1 = x_n / φ
    ⍝ Converges to 0 (entropy shedding)
    x steps←⍵
    'steps must be positive' Assert steps>0
    values←x
    {values,←⊃¯1↑values÷PHI}⍣steps⍬
    values
}

FibContractionTable←{
    ⍝ Returns table: step | fib | ratio | contraction
    N←⍵
    fibs←FibSeq N
    ratios←(1↓fibs)÷¯1↓fibs
    contraction←PHI-ratios
    ⍉↑(⍳N-1) (1↓fibs) ratios |contraction
}

⍝ ── Transform 2: Phinary Entropy Mapping ────────────────────────────────────

PhinEntropy←{
    ⍝ Compute phinary entropy of a probability vector
    ⍝ H_φ(p) = -Σ pᵢ ×_φ log_φ(pᵢ)
    ⍝ Uses natural log scaled to phi base
    probs←⍵
    'probabilities must sum to 1' Assert 0.999<+/probs
    'all probabilities non-negative' Assert ∧/probs≥0
    logphi←{(⍟⍵)÷⍟PHI}
    terms←probs×logphi probs⌈1e-10
    -+/terms
}

EntropyGateCheck←{
    ⍝ Returns 1 (OPEN) if entropy < 0.21 threshold
    ⍝ Returns 0 (FAILED) if entropy ≥ 0.21
    entropy←PhinEntropy ⍵
    threshold←0.21
    passed←entropy<threshold
    entropy threshold passed
}

⍝ ── Transform 3: Trust Vector Reduction ─────────────────────────────────────

⍝ EDAULC 7 axes (non-binary)
TRUST_AXES←'coherence' 'provenance' 'reversibility' 'consent' 'auditability' 'semantic_alignment' 'contradiction_resistance'

TrustNorm←{
    ⍝ L2 norm of trust vector — overall trust magnitude
    tv←⍵
    'trust vector must have 7 axes' Assert 7=≢tv
    'all axes must be in [0,1]' Assert ∧/(tv≥0)∧tv≤1
    (+/tv*2)*0.5
}

TrustReduction←{
    ⍝ Reduce two trust vectors to agreement score
    ⍝ Agreement = cosine similarity between vectors
    tv1 tv2←⍵
    dot←+/tv1×tv2
    mag←(TrustNorm tv1)×TrustNorm tv2
    mag=0: 0
    dot÷mag
}

TrustRadarMatrix←{
    ⍝ N agents × 7 axes — radar chart data
    agents←⍵
    {TrustNorm ⍵}¨agents
}

⍝ ── Transform 4: Semantic Agreement Fold ────────────────────────────────────

SemanticFold←{
    ⍝ Fold N trust vectors into a consensus vector
    ⍝ Uses geometric mean per axis (not arithmetic — preserves proportionality)
    vectors←⍵
    N←≢vectors
    'need at least 2 vectors' Assert N≥2
    mat←↑vectors
    geoMean←{(×/⍵)*÷≢⍵}
    {geoMean mat[;⍵]}¨⍳7
}

SemanticAgreementScore←{
    ⍝ Overall agreement = TrustNorm of folded consensus ÷ max possible
    consensus←SemanticFold ⍵
    (TrustNorm consensus)÷(7*0.5)
}

⍝ ── Transform 5: 13-Node Resonance Matrix ───────────────────────────────────

MetatronDepths←0 0.5 1 2 2.5 2.5 3 3.5 3.5 4 5 5 6

ResonanceMatrix←{
    ⍝ 13×13 resonance matrix
    ⍝ Edge weight = 1 ÷ (1 + |depth_i - depth_j|)
    ⍝ Nodes at same depth resonate fully (weight=1)
    ⍝ Distant nodes resonate weakly
    depths←MetatronDepths
    N←≢depths
    {
        i←⍵
        {
            j←⍵
            di←depths[i]
            dj←depths[j]
            1÷1+|di-dj
        }¨⍳N
    }¨⍳N
}

⍝ ── Export: JSON-compatible table output ─────────────────────────────────────

ExportFibTable←{
    ⍝ Returns rows of [step, fib, ratio, contraction_delta]
    FibContractionTable ⍵
}

ExportResonanceMatrix←{
    ResonanceMatrix ⍬
}

⍝ ── Demo Console Runner ──────────────────────────────────────────────────────

RunTransformConsole←{
    ⎕←'═══ APL TRANSFORM CONSOLE ═══════════════════════════════'
    ⎕←''

    ⎕←'[1] Fibonacci Contraction (N=13 terms)'
    fibs←FibSeq 13
    ⎕←'    Sequence: ',⍕fibs
    ⎕←'    Ratio → φ: ',⍕(¯1↑1↓fibs)÷¯1↑¯2↑fibs
    ⎕←''

    ⎕←'[2] Phinary Entropy Gate Check'
    probs←0.5 0.3 0.15 0.05
    entropy threshold passed←EntropyGateCheck probs
    ⎕←'    Entropy: ',⍕entropy
    ⎕←'    Threshold: ',⍕threshold
    ⎕←'    Gate: ',(passed⊃'FAILED' 'OPEN')
    ⎕←''

    ⎕←'[3] Trust Vector Reduction (2 agents)'
    tv1←0.9 0.8 0.7 0.95 0.85 0.88 0.92
    tv2←0.7 0.9 0.6 0.80 0.75 0.82 0.78
    agreement←TrustReduction tv1 tv2
    ⎕←'    Agreement (cosine similarity): ',⍕agreement
    ⎕←''

    ⎕←'[4] Semantic Agreement Fold (3 agents)'
    agents←tv1 tv2 (0.85 0.75 0.80 0.90 0.70 0.88 0.85)
    score←SemanticAgreementScore agents
    ⎕←'    Consensus score: ',⍕score
    ⎕←''

    ⎕←'[5] 13-Node Resonance Matrix (first row)'
    mat←ResonanceMatrix ⍬
    ⎕←'    Node 1 resonance vector: ',⍕⊃mat
    ⎕←''

    ⎕←'═══ TRANSFORMS COMPLETE ══════════════════════════════════'
}
