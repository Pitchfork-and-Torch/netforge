$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSScriptRoot
$script = Join-Path $here 'src\New-NetForgeSampleReceipt.ps1'
$json = & $script | Out-String
if ($json -notmatch 'netforge-sample-receipt') { throw 'missing kind' }
if ($json -notmatch '"sample"\s*:\s*true') { throw 'missing sample flag' }
if ($json -notmatch 'No settings were changed') { throw 'missing honesty note' }
if ($json -match 'Fail closed on captive portal') { throw 'sample still says fail closed' }
if ($json -notmatch 'skips VPN adapters') { throw 'sample missing captive plan' }
Write-Output 'SAMPLE RECEIPT OK'
