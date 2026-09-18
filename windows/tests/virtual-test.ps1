$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
Write-Output 'NetForge Windows virtual tests'
& (Join-Path $here 'syntax.ps1')
& (Join-Path $here 'adapters.ps1')
& (Join-Path $here 'config-profiles.ps1')
& (Join-Path $here 'sample-receipt.ps1')
& (Join-Path $here 'doh-dns-servers.ps1')

$apply = Join-Path (Split-Path -Parent $here) 'src\NetworkAuto.ps1'
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    & $apply -DryRun | Out-Null
} finally {
    $ErrorActionPreference = $prevEap
}
Write-Output '  OK: NetworkAuto -DryRun'

$status = Join-Path (Split-Path -Parent $here) 'src\Get-NetForgeStatus.ps1'
$json = & $status -SkipDnsProbe -Json | Out-String
if ($json -notmatch '"tool":\s*"NetForge"') { throw 'status json missing tool' }
if ($json -notmatch '"platform":\s*"windows"') { throw 'status json missing platform' }
Write-Output '  OK: Get-NetForgeStatus -SkipDnsProbe -Json'

Write-Output 'WINDOWS VIRTUAL TESTS OK'
