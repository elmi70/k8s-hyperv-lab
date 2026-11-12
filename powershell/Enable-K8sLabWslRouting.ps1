#Requires -RunAsAdministrator
[CmdletBinding()]
param(
  [string]$WslDistribution = 'Ubuntu-26.04'
)
$ErrorActionPreference = 'Stop'
# Ansible runs in WSL 2, which sits on its own NAT network. The VMs are on the Hyper-V Default Switch
# (SSH management) and kube-lab-net, and Windows does not forward packets between those interfaces
# unless IP forwarding is enabled on them. Without it the Ansible connectivity check times out.
# Safe to re-run: interfaces that already forward are left alone.

# Start the distribution first so the WSL vEthernet interface exists.
wsl.exe -d $WslDistribution -- true
if ($LASTEXITCODE -ne 0) { throw "Could not start the WSL distribution '$WslDistribution'. Check 'wsl --list --verbose'." }

$pattern = 'vEthernet \((WSL|Default Switch|kube-lab-net)'
$interfaces = @(Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -match $pattern })
if (-not $interfaces) {
  Write-Warning 'No WSL, Default Switch or kube-lab-net vEthernet interfaces found; skipping IP forwarding setup.'
  return
}
foreach ($interface in $interfaces) {
  if ($interface.Forwarding -eq 'Enabled') {
    Write-Host "IP forwarding already enabled on '$($interface.InterfaceAlias)'."
  } else {
    Set-NetIPInterface -InterfaceIndex $interface.InterfaceIndex -AddressFamily IPv4 -Forwarding Enabled
    Write-Host "Enabled IP forwarding on '$($interface.InterfaceAlias)'." -ForegroundColor Green
  }
}
