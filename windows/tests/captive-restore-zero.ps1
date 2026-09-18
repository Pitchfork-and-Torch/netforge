# CaptiveAutoRestoreSeconds=0 must disable scheduling (not fall back to 900).
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$src = Get-Content -Raw (Join-Path $Root 'windows\src\Clear-CaptivePortal.ps1')

if ($src -notmatch '\$null -ne \$cfg\.CaptiveAutoRestoreSeconds') {
    Write-Error 'Clear-CaptivePortal.ps1 must use $null -ne for CaptiveAutoRestoreSeconds'
    exit 1
}
if ($src -match '\$secs = if \(\$cfg\.CaptiveAutoRestoreSeconds\)') {
    Write-Error 'Clear-CaptivePortal.ps1 still uses truthy CaptiveAutoRestoreSeconds check'
    exit 1
}

# Simulate the fixed expression
$cfg = @{ CaptiveAutoRestoreSeconds = 0 }
$secs = if ($null -ne $cfg.CaptiveAutoRestoreSeconds) { [int]$cfg.CaptiveAutoRestoreSeconds } else { 900 }
if ($secs -ne 0) {
    Write-Error "expected secs=0 for CaptiveAutoRestoreSeconds=0, got $secs"
    exit 1
}
$wouldSchedule = (-not $false) -and ($secs -gt 0)
if ($wouldSchedule) {
    Write-Error 'secs=0 must not schedule auto-restore'
    exit 1
}

$cfg2 = @{ CaptiveAutoRestoreSeconds = 900 }
$secs2 = if ($null -ne $cfg2.CaptiveAutoRestoreSeconds) { [int]$cfg2.CaptiveAutoRestoreSeconds } else { 900 }
if ($secs2 -ne 900) {
    Write-Error "expected secs=900, got $secs2"
    exit 1
}

$cfg3 = @{}
$secs3 = if ($null -ne $cfg3.CaptiveAutoRestoreSeconds) { [int]$cfg3.CaptiveAutoRestoreSeconds } else { 900 }
if ($secs3 -ne 900) {
    Write-Error "expected default 900 when missing, got $secs3"
    exit 1
}

Write-Host 'ok captive-restore-zero'
