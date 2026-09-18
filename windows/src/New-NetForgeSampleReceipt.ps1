#Requires -Version 5.1
<#
.SYNOPSIS
  Write a SAMPLE dry-run receipt. No system changes. No live DNS probes.
#>
[CmdletBinding()]
param(
    [string]$OutPath
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$version = (Get-Content (Join-Path $Root 'VERSION') -ErrorAction SilentlyContinue | Select-Object -First 1)
if (-not $version) { $version = 'unknown' }

$receipt = [ordered]@{
    kind = 'netforge-sample-receipt'
    tool = 'NetForge'
    platform = 'windows'
    version = "$version"
    sample = $true
    beats = @(
        'Prefer Ethernet when a wired adapter is up'
        'Resilient DNS (DoH when available)'
        'TCP tuning for lossy last-mile'
        'Fail closed on captive portal'
    )
    changed = @()
    note = 'SAMPLE. No settings were changed.'
}

$json = ($receipt | ConvertTo-Json -Depth 6)
if ($OutPath) {
    $dest = $OutPath
    $dir = Split-Path -Parent $dest
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -Path $dest -Value $json -Encoding utf8
}
Write-Output $json
