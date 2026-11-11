#Requires -RunAsAdministrator
[CmdletBinding()]
param(
  [string]$WslDistribution='Ubuntu-26.04',
  [switch]$SkipBoxCheck,
  # Prepare the nodes (OS, containerd, kubeadm/kubelet/kubectl, crictl, etcd tools) and stop
  # before kubeadm init, so you can snapshot a clean baseline and bootstrap the cluster yourself.
  [switch]$StopBeforeInit
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
function Assert-Command([string]$Name){if(-not(Get-Command $Name -ErrorAction SilentlyContinue)){throw "Required command missing: $Name"}}
foreach($c in 'vagrant','wsl','kubectl'){Assert-Command $c}
if((Get-Service vmms -ErrorAction Stop).Status -ne 'Running'){throw 'Hyper-V vmms service is not running.'}
$boxName=if($env:K8S_LAB_BOX){$env:K8S_LAB_BOX}else{'ubuntu2604-hyperv'}
if(-not $SkipBoxCheck){$boxes=(vagrant box list) -join "`n";if($boxes -notmatch "(?m)^$([regex]::Escape($boxName))\s"){throw "Vagrant box $boxName is missing. Build/register it first (see docs/image-build.md)."}}
& "$PSScriptRoot\New-K8sLabNetwork.ps1"
Push-Location "$root\vagrant"
try {
  vagrant up --provider=hyperv
  if($LASTEXITCODE -ne 0){throw "vagrant up failed with exit code $LASTEXITCODE"}
  & "$PSScriptRoot\Add-K8sLabNic.ps1"
  vagrant provision --provision-with lab-net
  if($LASTEXITCODE -ne 0){throw "Static lab NIC provisioning failed with exit code $LASTEXITCODE"}
} finally { Pop-Location }
& "$PSScriptRoot\New-K8sAnsibleInventory.ps1" -WslDistribution $WslDistribution
$wslRoot=(wsl.exe -d $WslDistribution -- wslpath -a $root | Select-Object -First 1).Trim()
if(-not $wslRoot){throw 'Failed to convert repository path for WSL.'}
$playbooks=@(
  'preflight.yml',
  'prerequisites.yml',
  'kubernetes-packages.yml',
  'install-node-tools.yml',
  'bootstrap-cluster.yml',
  'install-cni.yml',
  'install-metallb.yml',
  'install-metrics-server.yml',
  'install-local-path.yml',
  'install-traefik.yml',
  'validate-cluster.yml'
)
if($StopBeforeInit){$playbooks=$playbooks[0..($playbooks.IndexOf('install-node-tools.yml'))]}
$ping="cd '$wslRoot' && ansible all -i ansible/inventory/hosts.yml -m ping"
Write-Host "`n>>> $ping" -ForegroundColor Cyan
wsl.exe -d $WslDistribution -- bash -lc $ping
if($LASTEXITCODE -ne 0){throw "Ansible connectivity check failed with exit code $LASTEXITCODE"}
foreach($playbook in $playbooks){
  $command="cd '$wslRoot' && ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/$playbook"
  Write-Host "`n>>> $command" -ForegroundColor Cyan
  wsl.exe -d $WslDistribution -- bash -lc $command
  if($LASTEXITCODE -ne 0){throw "Playbook $playbook failed with exit code $LASTEXITCODE"}
}
if($StopBeforeInit){
  Write-Host "Nodes prepared; stopped before kubeadm init. Snapshot with .\powershell\Save-K8sSnapshot.ps1, then run 'kubeadm init' on control1 (vagrant ssh control1)." -ForegroundColor Green
  return
}
$source=Join-Path $root 'artifacts\kubeconfig'
$target=Join-Path $HOME '.kube\config'
if(-not(Test-Path $source)){throw "Expected kubeconfig not found: $source"}
New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
# Do not silently destroy an existing kubeconfig (contexts for other clusters): back it up first.
if((Test-Path $target) -and ((Get-FileHash $source).Hash -ne (Get-FileHash $target).Hash)){
  $backup="$target.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  Copy-Item $target $backup
  Write-Host "Existing kubeconfig backed up to $backup" -ForegroundColor Yellow
}
Copy-Item $source $target -Force
kubectl --kubeconfig $target get nodes -o wide
kubectl --kubeconfig $target get svc -A
Write-Host "Kubernetes lab ready: Calico + MetalLB + Metrics Server + local-path storage + Traefik Gateway API. Kubeconfig: $target" -ForegroundColor Green
