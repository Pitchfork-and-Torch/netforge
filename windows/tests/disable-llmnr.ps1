$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSScriptRoot
$apply = Join-Path $here 'src\NetworkAuto.ps1'
$corp = Join-Path $here 'config\profiles\corporate.psd1'
$out = & $apply -DryRun -ConfigPath $corp 2>&1 | Out-String
if ($out -notmatch 'keep LLMNR \(DisableLlmnr=false\)') {
    throw "corporate dry-run should plan keep LLMNR; got:`n$out"
}
Write-Output '  OK: corporate dry-run keeps LLMNR'
$priv = Join-Path $here 'config\profiles\privacy-max.psd1'
$out2 = & $apply -DryRun -ConfigPath $priv 2>&1 | Out-String
if ($out2 -notmatch 'LLMNR off \(DisableLlmnr=true\)') {
    throw "privacy-max dry-run should plan LLMNR off; got:`n$out2"
}
Write-Output '  OK: privacy-max dry-run disables LLMNR'
Write-Output 'DISABLE LLMNR TESTS OK'
