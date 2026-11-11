#Requires -RunAsAdministrator
param([string]$SwitchName='kube-lab-net',[string]$NatName='kube-lab-nat',[string]$Prefix='192.168.77.0/24',[string]$Gateway='192.168.77.1')
if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) { New-VMSwitch -Name $SwitchName -SwitchType Internal | Out-Null }
$ifIndex=(Get-NetAdapter -Name "vEthernet ($SwitchName)" -ErrorAction Stop).ifIndex
if (-not (Get-NetIPAddress -InterfaceIndex $ifIndex -IPAddress $Gateway -ErrorAction SilentlyContinue)) { New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress $Gateway -PrefixLength 24 | Out-Null }
if (-not (Get-NetNat -Name $NatName -ErrorAction SilentlyContinue)) { New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix $Prefix | Out-Null }
Write-Host "Hyper-V lab network ready: $SwitchName / $Prefix"
