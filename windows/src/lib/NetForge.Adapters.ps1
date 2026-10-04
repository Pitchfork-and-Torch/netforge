#Requires -Version 5.1
# Adapter classification shared by apply, status, and captive recovery.

function Get-NetForgeAdapterBlob {
    param($Adapter)
    if ($null -eq $Adapter) { return '' }
    if ($Adapter -is [string]) { return [string]$Adapter }
    return ('{0} {1}' -f $Adapter.Name, $Adapter.InterfaceDescription)
}

function Test-NetForgeVpnAdapter {
    param($Adapter)
    $blob = Get-NetForgeAdapterBlob $Adapter
    return [bool]($blob -match 'VPN|TAP|TUN|Wintun|WireGuard|OpenVPN|NordLynx|AnyConnect|GlobalProtect|Zscaler|Fortinet|Tailscale|ZeroTier|WARP|warp|Mullvad|ProtonVPN|Proton|Outline')
}

function Test-NetForgeWirelessAdapter {
    param($Adapter)
    if ($null -eq $Adapter) { return $false }
    if ($Adapter -is [string]) {
        return [bool]($Adapter -match 'Wi-?Fi|Wireless|802\.11|WLAN')
    }
    return [bool](
        $Adapter.InterfaceDescription -match 'Wi-?Fi|Wireless|802\.11|WLAN' -or
        $Adapter.MediaType -eq 'Native 802.11' -or
        $Adapter.Name -match 'Wi-?Fi'
    )
}

function Test-NetForgeEthernetAdapter {
    param($Adapter)
    if ($null -eq $Adapter) { return $false }
    if (Test-NetForgeWirelessAdapter $Adapter) { return $false }
    if (Test-NetForgeVpnAdapter $Adapter) { return $false }
    if ($Adapter -is [string]) {
        return [bool]($Adapter -match 'Ethernet|Realtek|Intel.*I2|USB.*Ethernet|2\.5G|Gigabit|\bLAN\b')
    }
    return [bool](
        $Adapter.InterfaceDescription -match 'Ethernet|Realtek|Intel.*I2|USB.*Ethernet|2\.5G|Gigabit|\bLAN\b' -or
        $Adapter.MediaType -match '802\.3'
    )
}

function Test-NetForgeShouldSkipVpn {
    param(
        $Adapter,
        [bool]$RespectVpn = $true
    )
    if (-not $RespectVpn) { return $false }
    return Test-NetForgeVpnAdapter $Adapter
}
