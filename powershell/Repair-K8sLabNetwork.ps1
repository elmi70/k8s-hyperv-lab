#Requires -RunAsAdministrator
& "$PSScriptRoot\New-K8sLabNetwork.ps1"
Get-VM -Name 'k8s-lab-*' -ErrorAction SilentlyContinue | ForEach-Object { Connect-VMNetworkAdapter -VMName $_.Name -SwitchName 'kube-lab-net' }
