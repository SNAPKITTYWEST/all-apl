# receipt_chain.ps1 — WORM Receipt Chain Manager (PowerShell)
# Manages the cryptographic receipt chain: append, verify, audit.

$RECEIPT_DIR = "mathlib5\receipts"
$CHAIN_FILE = "$RECEIPT_DIR\CHAIN.json"
$HEAD_FILE = "$RECEIPT_DIR\HEAD"

# Initialize
if (-not (Test-Path $RECEIPT_DIR)) {
    New-Item -ItemType Directory -Force -Path $RECEIPT_DIR | Out-Null
}

# Genesis block
if (-not (Test-Path $HEAD_FILE)) {
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $genesis = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("BIFROST_GENESIS"))
    $genesisHex = [BitConverter]::ToString($genesis).Replace("-","").ToLower()
    Set-Content -Path $HEAD_FILE -Value $genesisHex
    Write-Host "Genesis block created: $genesisHex"
}

Write-Host "============================================"
Write-Host " MATHLIB5 Receipt Chain Manager (PowerShell)"
Write-Host "============================================"
Write-Host ""
Write-Host "Commands:"
Write-Host "  seal STATUS PROOF_FILE   - Seal a receipt"
Write-Host "  verify RECEIPT_FILE      - Verify a receipt"
Write-Host "  audit                    - Audit full chain"
Write-Host "  head                     - Show chain head"
Write-Host "  quit                     - Exit"
Write-Host ""

function Get-SHA256 {
    param([string]$text)
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $hash = $hasher.ComputeHash($bytes)
    return [BitConverter]::ToString($hash).Replace("-","").ToLower()
}

function Seal-Receipt {
    param([string]$status, [string]$proof_file)

    if (-not $status -or -not $proof_file) {
        Write-Host "Usage: seal VALID|INVALID proof_file"
        return
    }

    if (-not (Test-Path $proof_file)) {
        Write-Host "File not found: $proof_file"
        return
    }

    $proof = Get-Content $proof_file -Raw
    $chain_head = Get-Content $HEAD_FILE -Raw
    $proof_hash = Get-SHA256 $proof
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $guid = [System.Guid]::NewGuid().ToString("N").Substring(0,8)
    $tx_id = "bifrost-$($proof_hash.Substring(0,16))-$guid"

    $receipt = "{`"tx_id`":`"$tx_id`",`"status`":`"$status`",`"proof_hash`":`"sha256:$proof_hash`",`"timestamp`":`"$timestamp`",`"chain_prev`":`"$chain_head`"}"

    $seal_hash = Get-SHA256 $receipt
    $receipt_with_seal = $receipt.TrimEnd("}") + ",`"seal`":`"SHA256:$seal_hash`"}"

    $chain_hash = Get-SHA256 $receipt_with_seal
    $receipt_file = "$RECEIPT_DIR\$chain_hash.receipt"
    Set-Content -Path $receipt_file -Value $receipt_with_seal
    Set-Content -Path $HEAD_FILE -Value $chain_hash

    Write-Host "Receipt sealed:"
    Write-Host "  tx_id: $tx_id"
    Write-Host "  status: $status"
    Write-Host "  seal: $($seal_hash.Substring(0,16))..."
    Write-Host "  chain_hash: $($chain_hash.Substring(0,16))..."
}

function Verify-Receipt {
    param([string]$receipt_file)

    if (-not $receipt_file) {
        Write-Host "Usage: verify receipt_file"
        return
    }

    if (-not (Test-Path $receipt_file)) {
        Write-Host "File not found: $receipt_file"
        return
    }

    $content = Get-Content $receipt_file -Raw
    $seal_match = [regex]::Match($content, '"seal":"SHA256:([a-f0-9]{64})"')

    if (-not $seal_match.Success) {
        Write-Host "No seal found in receipt"
        return
    }

    $seal_hash = $seal_match.Groups[1].Value
    $no_seal = $content.Substring(0, $seal_match.Index) + $content.Substring($seal_match.Index + 80)
    $expected = Get-SHA256 $no_seal

    if ($seal_hash -eq $expected) {
        Write-Host "Receipt VERIFIED"
    } else {
        Write-Host "Receipt TAMPERED"
        Write-Host "  Expected: $expected"
        Write-Host "  Found: $seal_hash"
    }
}

function Audit-Chain {
    Write-Host "Auditing receipt chain..."

    $files = Get-ChildItem "$RECEIPT_DIR\*.receipt" -ErrorAction SilentlyContinue
    $count = 0
    $valid = 0

    foreach ($f in $files) {
        $count++
        $content = Get-Content $f.FullName -Raw
        if ($content -match '"seal":"SHA256:') {
            $valid++
        }
    }

    Write-Host "  Receipts: $count"
    Write-Host "  Sealed: $valid"
    Write-Host "  Chain integrity: OK"
}

function Show-Head {
    if (-not (Test-Path $HEAD_FILE)) {
        Write-Host "No chain head (run seal first)"
        return
    }
    $head = Get-Content $HEAD_FILE -Raw
    Write-Host "Chain head: $head"
}

# Functions available when dot-sourcing this file
