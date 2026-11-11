#Requires -RunAsAdministrator
Get-VM -Name 'k8s-lab-*' -ErrorAction Stop | Stop-VM
