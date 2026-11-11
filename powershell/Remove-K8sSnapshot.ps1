#Requires -RunAsAdministrator
param([Parameter(Mandatory=$true)][string]$Name)
Get-VM -Name 'k8s-lab-*' -ErrorAction Stop | ForEach-Object { Get-VMSnapshot -VM $_ -Name $Name -ErrorAction Stop | Remove-VMSnapshot -Confirm:$false }
