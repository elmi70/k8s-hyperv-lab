# Prerequisites

## Where to clone the repository

Clone to a plain local path such as `C:\labs\k8s-hyperv-lab` or `C:\src\k8s-hyperv-lab`, **not** into OneDrive or another synced folder. The Packer build writes a multi-gigabyte `.box` and a build disk under `packer\output`, and Vagrant keeps state in `vagrant\.vagrant`; cloud sync can slow or interfere with both.

**Avoid spaces in the path.** A path such as `C:\Users\you\OneDrive - Company\Desktop\k8s-hyperv-lab` makes `vagrant box add` fail with `bad URI(is not URI?)`, and spaces also cause quoting problems in the scripts. Moving the repository does not move the git-ignored `packer\output\*.box`; rebuild the box or copy it across.

## PowerShell 7 and script execution

Run every script from an **elevated PowerShell 7** window (`pwsh`, run as administrator; the prompt shows `PowerShell 7.x`; check with `$PSVersionTable.PSVersion`). Windows PowerShell 5.1 (`powershell.exe`) has a stricter execution policy and fails with `... is not digitally signed`.

If PowerShell 7 shows a "Security warning: Run only scripts that you trust" prompt, the files carry a download mark. Clear it once after cloning or copying the repository:

```powershell
Get-ChildItem -Recurse -Filter *.ps1 | Unblock-File
```

## Resources

- **RAM:** the three VMs use 16 GiB by default (see the sizing table in the README). If your free memory is lower, shrink them with `K8S_LAB_CONTROL_MEMORY_MB` and `K8S_LAB_WORKER_MEMORY_MB`; see "Low-memory laptops" in the README. Check free memory with `systeminfo | Select-String "Memory"`.
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
$tools = @("git", "gh", "packer", "oscdimg", "vagrant", "kubectl", "wsl")
foreach ($tool in $tools) {
  Write-Host "`n=== $tool ===" -ForegroundColor Cyan
  Get-Command $tool -ErrorAction SilentlyContinue | Select-Object Name, Source
}
```

Install commonly missing tools:

```powershell
winget install --id Hashicorp.Packer -e
winget install --id Microsoft.OSCDIMG -e
winget install --id Hashicorp.Vagrant -e
winget install --id GitHub.cli -e
winget install --id Kubernetes.kubectl -e
```

`oscdimg` is only needed to build the box locally. Packer calls it to create the small ISO that carries the Ubuntu autoinstall files (`user-data`, `meta-data`); without it `packer build` fails with "could not find a supported CD ISO creation command". Open a new terminal after installing so PATH updates.

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

### WSL must be able to reach the Hyper-V switches

Ansible runs inside WSL 2, which sits on its own NAT network (for example `172.30.64.0/20`), while the VMs are on the Hyper-V Default Switch (`172.24.x.x`, used for SSH) and `kube-lab-net` (`192.168.77.0/24`). Windows does not forward packets between those switches by default, so the deploy can stop at the Ansible connectivity check with `ssh: connect to host 172.24.x.x port 22: Connection timed out` even though the VMs are running.

Enabling IP forwarding on the three `vEthernet` interfaces (WSL, Default Switch and `kube-lab-net`) fixes this. `Deploy-K8sLab.ps1` does it for you: it runs `powershell\Enable-K8sLabWslRouting.ps1`, which starts the WSL distribution (so its interface exists) and enables forwarding on any of those interfaces that do not have it yet. The script is idempotent and needs the elevated session you already use. You can also run it on its own:

```powershell
.\powershell\Enable-K8sLabWslRouting.ps1
```

The manual equivalent is:

```powershell
Get-NetIPInterface -AddressFamily IPv4 |
  Where-Object { $_.InterfaceAlias -match 'vEthernet \((WSL|Default Switch|kube-lab-net)' } |
  Set-NetIPInterface -Forwarding Enabled
```

Windows or WSL may reset the setting on restart; every deploy re-applies it, and you can re-run the script if the timeout returns later (for example after a reboot, when you start the lab with `Start-K8sLab.ps1` and use Ansible by hand). If forwarding is not enough, WSL's mirrored networking mode (`networkingMode=mirrored` in `%UserProfile%\.wslconfig`) is an alternative that I have not tested with this lab.

### Optional: cap WSL memory

WSL 2 can claim up to half of your RAM while Ansible runs. See "Low-memory laptops" in the README for a `.wslconfig` example.

## GitHub

The GitHub CLI is only needed to publish or download box releases (see [GitHub validation and releases](github-releases.md)); deploying the lab does not use it.

```powershell
gh auth login
gh auth status
```
