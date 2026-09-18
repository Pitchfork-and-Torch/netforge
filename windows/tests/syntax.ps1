$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSScriptRoot
$src = Join-Path $here 'src'

$files = @(Get-ChildItem -Path $src -Filter '*.ps1' -Recurse | Select-Object -ExpandProperty FullName)
if ($files.Count -lt 6) { throw "expected src scripts, got $($files.Count)" }

foreach ($f in $files) {
    $errs = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$null, [ref]$errs)
    if ($errs -and $errs.Count -gt 0) {
        throw "parse $($f): $($errs[0].Message)"
    }
    Write-Output "  OK: parse $(Split-Path $f -Leaf)"
}

$apply = Get-Content (Join-Path $src 'NetworkAuto.ps1') -Raw
if ($apply -notmatch 'NetForge\.Adapters\.ps1') { throw 'NetworkAuto does not load adapter lib' }
if ($apply -notmatch 'No settings changed') { throw 'NetworkAuto dry-run missing honesty line' }
$status = Get-Content (Join-Path $src 'Get-NetForgeStatus.ps1') -Raw
if ($status -notmatch 'Test-NetForgeVpnAdapter') { throw 'status still uses a private VPN regex' }
$captive = Get-Content (Join-Path $src 'Clear-CaptivePortal.ps1') -Raw
if ($captive -notmatch 'Test-NetForgeShouldSkipVpn') { throw 'captive portal does not skip VPN' }
if ($captive -notmatch 'CaptivePortalDns') { throw 'captive portal does not use CaptivePortalDns' }
Write-Output '  OK: apply/status/captive share adapter lib'

Write-Output 'SYNTAX OK'
