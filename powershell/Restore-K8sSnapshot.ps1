#Requires -RunAsAdministrator
param([Parameter(Mandatory=$true)][string]$Name)
Get-VM -Name 'k8s-lab-*' -ErrorAction Stop | ForEach-Object {$s=Get-VMSnapshot -VM $_ -Name $Name -ErrorAction Stop; Restore-VMSnapshot -VMSnapshot $s -Confirm:$false}
