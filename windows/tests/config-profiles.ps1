$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSScriptRoot
$configDir = Join-Path $here 'config'

function Assert-True([bool]$Value, [string]$Label) {
    if (-not $Value) { throw "FAIL: $Label" }
    Write-Output "  OK: $Label"
}

$files = @(
    (Join-Path $configDir 'defaults.psd1')
    (Join-Path $configDir 'defaults.example.psd1')
    (Join-Path $configDir 'profiles\home.psd1')
    (Join-Path $configDir 'profiles\travel.psd1')
    (Join-Path $configDir 'profiles\corporate.psd1')
    (Join-Path $configDir 'profiles\privacy-max.psd1')
)

foreach ($f in $files) {
    if (-not (Test-Path $f)) { throw "missing $f" }
    $cfg = Import-PowerShellDataFile $f
    Assert-True ($cfg.AppName -eq 'NetForge') "$(Split-Path $f -Leaf) AppName"
    Assert-True ($cfg.EthernetMetric -lt $cfg.WiFiMetricAlone) "$(Split-Path $f -Leaf) eth metric before wifi"
    Assert-True ($cfg.WiFiMetricAlone -le $cfg.WiFiMetricWithEth) "$(Split-Path $f -Leaf) wifi-with-eth not better than wifi-alone"
    Assert-True ([bool]$cfg.RespectVpn) "$(Split-Path $f -Leaf) RespectVpn default true"
    Assert-True (@($cfg.DnsServers).Count -ge 1) "$(Split-Path $f -Leaf) has DNS"
}

$corp = Import-PowerShellDataFile (Join-Path $configDir 'profiles\corporate.psd1')
Assert-True (-not [bool]$corp.DisableSshd) 'corporate keeps sshd'
Assert-True (-not [bool]$corp.DisableFileShare) 'corporate keeps file share'
Assert-True (-not [bool]$corp.DisableLlmnr) 'corporate keeps LLMNR'

$priv = Import-PowerShellDataFile (Join-Path $configDir 'profiles\privacy-max.psd1')
Assert-True ([bool]$priv.DisableSshd) 'privacy-max disables sshd'
Assert-True ([bool]$priv.DisableFileShare) 'privacy-max disables file share'
Assert-True ([bool]$priv.DisableLlmnr) 'privacy-max disables LLMNR'

Write-Output 'CONFIG PROFILES OK'
