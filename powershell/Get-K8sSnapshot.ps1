#Requires -RunAsAdministrator
Get-VM -Name 'k8s-lab-*' -ErrorAction Stop | Get-VMSnapshot | Select-Object VMName,Name,CreationTime
