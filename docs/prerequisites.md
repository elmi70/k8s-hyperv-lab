# Prerequisites

## Where to clone the repository

Clone to a plain local path such as `C:\src\k8s-hyperv-lab`, **not** into OneDrive or another synced folder. The Packer build writes a multi-gigabyte `.box` and a build disk under `packer\output`, and Vagrant keeps state in `vagrant\.vagrant`; cloud sync can slow or interfere with both. Avoiding spaces in the path also avoids quoting problems in the scripts.

## Resources

- **RAM:** the three VMs use 16 GiB (see the sizing table in the README).
- **Disk:** the Packer image disk is 32 GiB, and the VMs and checkpoints add more. Leave well over 100 GB free (this is a rough estimate, not a measured figure).

## Hyper-V

From elevated PowerShell:

```powershell
DISM.exe /Online /Enable-Feature /FeatureName:Microsoft-Hyper-V-All /All
```

Restart Windows, then verify:

```powershell
DISM.exe /Online /Get-FeatureInfo /FeatureName:Microsoft-Hyper-V-All
Get-Service vmms
Get-VMHost
Get-VMSwitch
systeminfo | Select-String "hypervisor"
```

### PowerShell 7: `Class not registered`

Some systems may return this from `Get-WindowsOptionalFeature` in PowerShell 7:

```text
Get-WindowsOptionalFeature: Class not registered
```

Do not treat that result alone as a Hyper-V failure. Use `DISM.exe` as shown above. Windows PowerShell 5.1 can also be used to query the optional feature:

```powershell
powershell.exe
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```

## Windows tools

```powershell
$tools = @("git", "gh", "packer", "vagrant", "kubectl", "wsl")
foreach ($tool in $tools) {
  Write-Host "`n=== $tool ===" -ForegroundColor Cyan
  Get-Command $tool -ErrorAction SilentlyContinue | Select-Object Name, Source
}
```

Install commonly missing tools:

```powershell
winget install --id Hashicorp.Packer -e
winget install --id Hashicorp.Vagrant -e
winget install --id GitHub.cli -e
winget install --id Kubernetes.kubectl -e
```

Verify:

```powershell
git --version
gh --version
packer --version
vagrant --version
kubectl version --client
wsl --version
wsl --list --verbose
```

## WSL Ubuntu

`Deploy-K8sLab.ps1` runs Ansible in the WSL distribution named `Ubuntu-26.04` by default (check with `wsl --list --verbose`). For a different distribution, pass `-WslDistribution <name>` to `Deploy-K8sLab.ps1` (and to `New-K8sAnsibleInventory.ps1` if you run it directly).

Inside the distribution:

```bash
for tool in ansible python3 ssh; do
  printf "%-10s " "$tool"
  command -v "$tool" || echo "MISSING"
done
```

If required:

```bash
sudo apt update
sudo apt install -y ansible
```

## GitHub

The GitHub CLI is only needed to publish or download box releases (see [GitHub validation and releases](github-releases.md)); deploying the lab does not use it.

```powershell
gh auth login
gh auth status
```
