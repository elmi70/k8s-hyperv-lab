# Prerequisites

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

```powershell
gh auth login
gh auth status
```
