$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSScriptRoot
$apply = Join-Path $here 'src\NetworkAuto.ps1'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("netforge-doh-" + [guid]::NewGuid().ToString() + ".psd1")
@'
@{
    AppName                   = 'NetForge'
    DnsServers                = @('9.9.9.9', '149.112.112.112')
    QosPrefix                 = 'NetForge-Priority'
    EthernetMetric            = 5
    WiFiMetricAlone           = 10
    WiFiMetricWithEth         = 50
    LockSeconds               = 90
    MaxLogLines               = 2000
    DisableSshd               = $true
    DisableFileShare          = $true
    DisableLlmnr              = $true
    HighPerformancePower      = $true
    RespectVpn                = $true
}
'@ | Set-Content -Path $tmp -Encoding UTF8
try {
    $out = & $apply -DryRun -ConfigPath $tmp 2>&1 | Out-String
    if ($out -notmatch 'DoH templates for 9\.9\.9\.9 / 149\.112\.112\.112 \(from DnsServers\)') {
        throw "Quad9 DnsServers dry-run should plan DoH for 9.9.9.9; got:`n$out"
    }
    if ($out -match 'DoH templates for 1\.1\.1\.1') {
        throw "Quad9 profile should not plan Cloudflare-only DoH; got:`n$out"
    }
    Write-Output '  OK: dry-run DoH follows DnsServers (Quad9)'
} finally {
    Remove-Item -Force $tmp -ErrorAction SilentlyContinue
}
Write-Output 'DOH DNS SERVERS TESTS OK'
