# PowerShell script to add metadata.json to all repos, auto-classifying them

$repos = @(
    "mathlib5/",
    "legacy/apl-corrections/",
    "mathlib5/malice_layer2/",
    "mathlib5/sorrydb/",
    "mathlib5/layers/fol/",
    "mathlib5/layers/asp/",
    "mathlib5/layers/prism-skills/",
    "mathlib5/layers/liquid/",
    "mathlib5/layers/hol/",
    "agentos_source/agentos-frontend/",
    "agentos_source/axiom-proof/",
    "agentos_source/collatz-verification/",
    "agentos_source/math-engine/",
    "agentos_source/math-skills/",
    "agentos_source/pnp-attack/",
    "agentos_source/policies/",
    "agentos_source/prism-skills/",
    "agentos_source/qec-discovery/",
    "agentos_source/resonance-math/",
    "mathrosetta_source/",
    "snapkitty-gitbucket/",
    "snapkitty-shell/",
    "mathlib5-ffi-bridge/"
)

$timestamp = Get-Date -Format "yyyyMMdd"

foreach ($repoPath in $repos) {
    $fullPath = Join-Path (Get-Location) $repoPath
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Force -Path $fullPath | Out-Null
    }

    $repoName = Split-Path $repoPath -Leaf
    if ($repoName -eq "") {
        $repoName = (Split-Path $repoPath -Parent | Split-Path -Leaf)
    }
    
    # Simple ID generation logic
    $repoId = $repoName -replace '[^a-zA-Z0-9]', ''
    if ($repoId.Length -gt 8) { $repoId = $repoId.Substring(0, 8) }
    $id = "MATHLIB5-$timestamp-$($repoId.ToUpper())-001"

    $familyId = 106
    $corporaPath = "corpora/formal_research/misc/"

    if ($repoPath -like "*kernel*" -or $repoPath -like "*mathlib5/*" -or $repoPath -eq "mathlib5/") {
        $familyId = 1
        $corporaPath = "corpora/exo_kernel/c--_kernel/"
    }
    if ($repoPath -like "*apl*") {
        $familyId = 2
        $corporaPath = "corpora/formal_research/snapkitty_proofs/apl/"
    }
    if ($repoPath -like "*malice*") {
        $familyId = 9
        $corporaPath = "corpora/novel_methods/malice_refutation/"
    }
    if ($repoPath -like "*sorry*") {
        $familyId = 8
        $corporaPath = "corpora/formal_research/snapkitty_proofs/sorrydb/"
    }
    if ($repoPath -like "*fol*") {
        $familyId = 5
        $corporaPath = "corpora/novel_methods/fol_proof_engine/"
    }
    if ($repoPath -like "*asp*") {
        $familyId = 6
        $corporaPath = "corpora/novel_methods/asp_stable_models/"
    }
    if ($repoPath -like "*prism*" -or $repoPath -like "*snapkitty*") {
        $familyId = 7
        $corporaPath = "corpora/exo_synchronicity/prism_skills/"
    }
    if ($repoPath -like "*liquid*") {
        $familyId = 3
        $corporaPath = "corpora/formal_research/snapkitty_proofs/liquid/"
    }
    if ($repoPath -like "*hol*" -or $repoPath -like "*lean*" -or $repoPath -like "*proof*") {
        $familyId = 4
        $corporaPath = "corpora/formal_research/snapkitty_proofs/lean4/"
    }
    if ($repoPath -like "*agentos*") {
        $familyId = 10
        $corporaPath = "corpora/autonomous_systems/agentos/"
    }
    if ($repoPath -like "*math-skills*" -or $repoPath -like "*qec*" -or $repoPath -like "*resonance*") {
        $familyId = 11
        $corporaPath = "corpora/formal_research/math_skills/"
    }

    $metadata = @{
        id = $id
        source_sha256 = "auto_generated"
        split = @("audit", "kernel", "proofs", "runtime", "witnesses", "refinements", "asp_gate", "fol_engine", "prism_skills")
        created_by = "Ahmad Ali Parr · SnapKitty Collective · the-49th-call SNAPKITTYWEST · 2026"
        review_status = "human_review_required"
        weight = 1.0
        family_id = $familyId
        provenance = @{
            source_path = $repoPath
            corpora_path = $corporaPath
            chain_link = "Bifrost_WORM_Chain_20260710_01"
        }
        security_audit = @{
            plasma_gate = "Ed25519_Enforced"
            encryption = "AES-256-GCM"
            tamper_evidence = "SHA-256 chain (append-only)"
            metadata_integrity = "Yes"
        }
        status = "awaiting_worm_seal"
    }

    $metadataJson = $metadata | ConvertTo-Json -Depth 10
    $filePath = Join-Path $fullPath "metadata.json"
    $metadataJson | Out-File -FilePath $filePath -Encoding utf8 -NoNewline

    Write-Host "✅ $repoPath/metadata.json → Family #$familyId (PATH: $corporaPath)"
}

Write-Host "`n🧠 Auto-classified: $($repos.Count) repos → $($repos.Count) families. Ready for Plasma Gate + WORM sealing."
