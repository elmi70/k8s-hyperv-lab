# GitHub validation and releases

GitHub-hosted `ubuntu-latest` runs source validation only (`.github/workflows/validate.yml`). The Hyper-V `.box` is built locally on the Windows Hyper-V host, because Packer's Hyper-V builder needs to start Hyper-V VMs, which hosted runners are not set up to do (no nested virtualization). Publishing is therefore run from the Hyper-V host rather than from Actions.

```mermaid
flowchart LR
 GH[GitHub repo] --> CI[GitHub-hosted validation]
 WIN[Windows + Hyper-V] --> PK[Packer build] --> BOX[.box] --> PUB[Publish-K8sBoxRelease.ps1] --> REL[GitHub Release]
```

## Publish

Authenticate once, then run from the repository root:

```powershell
gh auth login
.\powershell\Publish-K8sBoxRelease.ps1 -Build -Register   # elevated; tag auto-increments (v1.0.0, then next patch)
.\powershell\Publish-K8sBoxRelease.ps1 -Build -Tag v1.2.0 # elevated; explicit tag
.\powershell\Publish-K8sBoxRelease.ps1 -Tag v1.0.0        # publish an already-built box (no elevation needed)
```

`-Build` needs an **elevated** PowerShell 7 session. Without it the script publishes the box already in `packer\output`.

The script checks `gh` authentication, optionally runs `packer init/fmt/validate/build -force`, refuses boxes of 2 GiB or more (the GitHub Releases per-file limit), writes `SHA256SUMS`, and creates or updates the release. Re-running with an existing tag replaces the assets. `-Register` also adds the box to Vagrant on this machine.

A release contains `ubuntu-26.04.1-hyperv.box` and `SHA256SUMS`.

To build without publishing, see [Image build](image-build.md).

## Using a published box instead of building

```powershell
gh release download --pattern 'ubuntu-26.04.1-hyperv.box' --pattern 'SHA256SUMS' --dir .\box-download
cd .\box-download
(Get-FileHash .\ubuntu-26.04.1-hyperv.box -Algorithm SHA256).Hash.ToLower()   # compare with SHA256SUMS
vagrant box add ubuntu2604-hyperv .\ubuntu-26.04.1-hyperv.box
```

`gh release download` fetches the latest release by default; pass a tag to pick another.
