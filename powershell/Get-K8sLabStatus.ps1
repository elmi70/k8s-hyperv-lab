#Requires -RunAsAdministrator
Get-VM -Name 'k8s-lab-*' -ErrorAction SilentlyContinue | Select-Object Name,State,CPUUsage,MemoryAssigned,Uptime
