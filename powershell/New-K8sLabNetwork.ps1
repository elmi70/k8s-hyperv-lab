#Requires -RunAsAdministrator
[CmdletBinding()]
param(
  [string]$SwitchName = 'kube-lab-net',
  [string]$NatName = 'kube-lab-nat',
  [string]$Prefix = '192.168.77.0/24',
  [string]$Gateway = '192.168.77.1'
)
$ErrorActionPreference = 'Stop'
$adapterName = "vEthernet ($SwitchName)"
$prefixLength = [int]($Prefix -split '/')[1]

# Preflight: the lab subnet must not already be routed through another interface
# (Docker, WSL, another lab, VPN...). Our own adapter and NAT are fine.
$conflict = @(Get-NetRoute -DestinationPrefix $Prefix -ErrorAction SilentlyContinue |
    Where-Object { $_.InterfaceAlias -ne $adapterName })
if ($conflict) {
  throw "Subnet $Prefix is already routed via interface '$($conflict[0].InterfaceAlias)'. Free it or choose another prefix (-Prefix/-Gateway) before continuing."
}
$otherNat = @(Get-NetNat -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne $NatName -and $_.InternalIPInterfaceAddressPrefix -eq $Prefix })
if ($otherNat) {
  throw "NAT '$($otherNat[0].Name)' already owns $Prefix. Remove it or choose another prefix."
}

if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
  New-VMSwitch -Name $SwitchName -SwitchType Internal | Out-Null
}

# Exact-name match so look-alike adapters are never picked up.
$adapters = @(Get-NetAdapter -ErrorAction Stop | Where-Object { $_.Name -eq $adapterName })
if ($adapters.Count -eq 0) { throw "Could not find adapter named '$adapterName' for switch '$SwitchName'." }
if ($adapters.Count -gt 1) { throw "Found $($adapters.Count) adapters named '$adapterName'; remove the duplicates (Get-NetAdapter) and retry." }
$ifIndex = $adapters[0].ifIndex

if (-not (Get-NetIPAddress -InterfaceIndex $ifIndex -IPAddress $Gateway -ErrorAction SilentlyContinue)) {
  New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress $Gateway -PrefixLength $prefixLength | Out-Null
}
if (-not (Get-NetNat -Name $NatName -ErrorAction SilentlyContinue)) {
  New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix $Prefix | Out-Null
}
Write-Host "Hyper-V lab network ready: $SwitchName / $Prefix (gateway $Gateway)"
