$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSScriptRoot
. (Join-Path $here 'src\lib\NetForge.Adapters.ps1')

function New-FakeAdapter {
    param([string]$Name, [string]$Description, [string]$MediaType = '802.3')
    [pscustomobject]@{
        Name                  = $Name
        InterfaceDescription  = $Description
        MediaType             = $MediaType
    }
}

function Assert-True([bool]$Value, [string]$Label) {
    if (-not $Value) { throw "FAIL: $Label" }
    Write-Output "  OK: $Label"
}

$nord = New-FakeAdapter 'NordLynx' 'NordLynx Tunnel'
$wg = New-FakeAdapter 'WireGuard Tunnel' 'WireGuard Tunnel'
$forti = New-FakeAdapter 'fortissl' 'Fortinet SSL VPN'
$zt = New-FakeAdapter 'ZeroTier One' 'ZeroTier Virtual Adapter'
$outline = New-FakeAdapter 'Outline' 'Outline TAP Adapter'
$wifi = New-FakeAdapter 'Wi-Fi' 'Intel Wi-Fi 6 AX201 160MHz' 'Native 802.11'
$eth = New-FakeAdapter 'Ethernet' 'Realtek PCIe GbE Family Controller'
$usb = New-FakeAdapter 'Ethernet 2' 'USB 2.5G Ethernet'
$intel = New-FakeAdapter 'Ethernet' 'Intel(R) Ethernet Connection I219-V'

Assert-True (Test-NetForgeVpnAdapter $nord) 'NordLynx is VPN (status used to miss this)'
Assert-True (Test-NetForgeVpnAdapter $wg) 'WireGuard is VPN'
Assert-True (Test-NetForgeVpnAdapter $forti) 'Fortinet is VPN'
Assert-True (Test-NetForgeVpnAdapter $zt) 'ZeroTier is VPN'
Assert-True (Test-NetForgeVpnAdapter $outline) 'Outline TAP is VPN'
Assert-True (-not (Test-NetForgeVpnAdapter $eth)) 'Realtek Ethernet is not VPN'
Assert-True (Test-NetForgeWirelessAdapter $wifi) 'AX201 is Wi-Fi'
Assert-True (-not (Test-NetForgeWirelessAdapter $eth)) 'Realtek is not Wi-Fi'
Assert-True (Test-NetForgeEthernetAdapter $eth) 'Realtek is Ethernet'
Assert-True (Test-NetForgeEthernetAdapter $usb) 'USB 2.5G is Ethernet'
Assert-True (Test-NetForgeEthernetAdapter $intel) 'Intel I219 is Ethernet'
Assert-True (-not (Test-NetForgeEthernetAdapter $wifi)) 'Wi-Fi is not Ethernet'
Assert-True (-not (Test-NetForgeEthernetAdapter $nord)) 'NordLynx is not Ethernet'
Assert-True (Test-NetForgeShouldSkipVpn -Adapter $nord -RespectVpn $true) 'skip VPN when RespectVpn'
Assert-True (-not (Test-NetForgeShouldSkipVpn -Adapter $nord -RespectVpn $false)) 'do not skip VPN when RespectVpn false'
Assert-True (-not (Test-NetForgeShouldSkipVpn -Adapter $eth -RespectVpn $true)) 'do not skip Ethernet'

Write-Output 'ADAPTERS OK'
