⍝ run_all.apl
⍝ Pure APL demonstration runner. Load this after the src modules in an APL session.
⍝ No Python. No wrappers. No MLIR.

⎕IO←1

RunAll←{
    stability←RunPIRTMStabilityDemo ⍬
    domain←RunDomainDemo ⍬
    omega←RunOmegaDemo ⍬
    zero←RunZeroproofDemo ⍬
    morphism←RunMorphismDemo ⍬
    stability domain omega zero morphism
}

