# NetBIOS/SSDP must follow DisableFileShare (corporate keeps discovery).
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSScriptRoot
$apply = Join-Path $here 'src\NetworkAuto.ps1'
$corp = Join-Path $here 'config\profiles\corporate.psd1'
$out = & $apply -DryRun -ConfigPath $corp 2>&1 | Out-String
if ($out -notmatch 'keep NetBIOS/SSDP \(DisableFileShare=false\)') {
    throw "corporate dry-run should plan keep NetBIOS/SSDP; got:`n$out"
}
if ($out -match 'Disable NetBIOS; SSDP disabled') {
    throw "corporate dry-run must not disable NetBIOS/SSDP; got:`n$out"
}
Write-Output '  OK: corporate dry-run keeps NetBIOS/SSDP'
$priv = Join-Path $here 'config\profiles\privacy-max.psd1'
$out2 = & $apply -DryRun -ConfigPath $priv 2>&1 | Out-String
if ($out2 -notmatch 'Disable NetBIOS; SSDP disabled \(DisableFileShare=true\)') {
    throw "privacy-max dry-run should disable NetBIOS/SSDP; got:`n$out2"
}
Write-Output '  OK: privacy-max dry-run disables NetBIOS/SSDP'
Write-Output 'NETBIOS FILE-SHARE TESTS OK'
