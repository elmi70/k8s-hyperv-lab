#Requires -RunAsAdministrator
[CmdletBinding()]
param(
  [string]$SwitchName = 'kube-lab-net',
  [string]$VmPrefix = 'k8s-lab-',
  [string]$AdapterName = 'kube-lab'
)
$ErrorActionPreference = 'Stop'
# Ensure every lab VM has a second NIC (named $AdapterName) connected to the lab switch.
# The first NIC stays on the Default Switch for Vagrant management/DHCP.
$vms = @(Get-VM -Name "$VmPrefix*" -ErrorAction SilentlyContinue)
if (-not $vms) { throw "No VMs matching '$VmPrefix*' found. Run 'vagrant up' first." }
foreach ($vm in $vms) {
  $nic = Get-VMNetworkAdapter -VM $vm -Name $AdapterName -ErrorAction SilentlyContinue
  if (-not $nic) {
    Add-VMNetworkAdapter -VM $vm -SwitchName $SwitchName -Name $AdapterName
    Write-Host "$($vm.Name): added NIC '$AdapterName' on $SwitchName"
  } elseif ($nic.SwitchName -ne $SwitchName) {
    Connect-VMNetworkAdapter -VMNetworkAdapter $nic -SwitchName $SwitchName
    Write-Host "$($vm.Name): reconnected NIC '$AdapterName' to $SwitchName"
  } else {
    Write-Host "$($vm.Name): NIC '$AdapterName' already on $SwitchName"
  }
}
