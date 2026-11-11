#Requires -RunAsAdministrator
[CmdletBinding()]
param()
$checks = @()
$checks += [pscustomobject]@{ Check = 'vmms'; Pass = ((Get-Service vmms -ErrorAction SilentlyContinue).Status -eq 'Running') }
foreach ($cmd in 'git', 'packer', 'vagrant', 'kubectl', 'wsl') {
  $checks += [pscustomobject]@{ Check = $cmd; Pass = [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
}
$checks | Format-Table -AutoSize

# Optional items: reported, but they do not fail the preflight.
# gh is only needed to publish or download box releases; the lab switch is created by Deploy-K8sLab.ps1.
$notes = @()
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  $notes += 'gh not found: only needed to publish or download box releases.'
}
if (-not (Get-VMSwitch -Name 'kube-lab-net' -ErrorAction SilentlyContinue)) {
  $notes += "Switch 'kube-lab-net' not found: Deploy-K8sLab.ps1 creates it."
}
foreach ($n in $notes) { Write-Warning $n }

if ($checks.Pass -contains $false) { exit 1 }
