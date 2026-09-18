$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSScriptRoot
$script = Join-Path $here 'src\New-NetForgeSampleReceipt.ps1'
$json = & $script | Out-String
if ($json -notmatch 'netforge-sample-receipt') { throw 'missing kind' }
if ($json -notmatch '"sample"\s*:\s*true') { throw 'missing sample flag' }
if ($json -notmatch 'No settings were changed') { throw 'missing honesty note' }
Write-Output 'SAMPLE RECEIPT OK'
