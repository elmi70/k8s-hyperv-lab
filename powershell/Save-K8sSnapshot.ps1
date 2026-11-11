#Requires -RunAsAdministrator
param([Parameter(Mandatory=$true)][string]$Name)
$vms=Get-VM -Name 'k8s-lab-*' -ErrorAction Stop
if($vms.Count -ne 3){throw 'Expected exactly three lab VMs.'}
$vms | ForEach-Object { Checkpoint-VM -VM $_ -SnapshotName $Name }
