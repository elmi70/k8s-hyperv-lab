[CmdletBinding()]
param(
  # Release tag, e.g. v1.0.0. If omitted, the next patch after the latest release is used (v1.0.0 for the first).
  [string]$Tag,
  [string]$BoxPath = "$(Split-Path $PSScriptRoot -Parent)\packer\output\ubuntu-26.04.1-hyperv.box",
  # Build the box with Packer first (needs elevated PowerShell + Hyper-V).
  [switch]$Build,
  # Register the freshly built/published box with Vagrant on this machine.
  [switch]$Register,
  [string]$BoxName = 'ubuntu2604-hyperv'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$maxBytes = 2GB   # GitHub Releases per-file limit is 2 GiB

foreach ($c in 'gh') { if (-not (Get-Command $c -ErrorAction SilentlyContinue)) { throw "Required command missing: $c" } }
gh auth status *> $null
if ($LASTEXITCODE -ne 0) { throw 'GitHub CLI is not authenticated. Run: gh auth login' }

if ($Build) {
  if (-not (Get-Command packer -ErrorAction SilentlyContinue)) { throw 'Required command missing: packer' }
  Push-Location (Join-Path $root 'packer')
  try {
    foreach ($step in @('init .', 'fmt -check -recursive .', 'validate .', 'build -force .')) {
      Write-Host ">>> packer $step" -ForegroundColor Cyan
      & packer @($step -split ' ')
      if ($LASTEXITCODE -ne 0) { throw "packer $step failed with exit code $LASTEXITCODE" }
    }
  } finally { Pop-Location }
}

if (-not (Test-Path $BoxPath)) { throw "Box not found: $BoxPath (use -Build to create it)" }
$box = Get-Item $BoxPath
if ($box.Length -ge $maxBytes) {
  throw ("Box is {0:N2} GiB; GitHub Releases allows files under 2 GiB. Shrink the image (zero free space, smaller disk) or host it elsewhere." -f ($box.Length / 1GB))
}

if (-not $Tag) {
  $latest = (gh release list --limit 1 --json tagName --jq '.[0].tagName' 2>$null)
  if ($latest -match '^v(\d+)\.(\d+)\.(\d+)$') { $Tag = 'v{0}.{1}.{2}' -f $matches[1], $matches[2], ([int]$matches[3] + 1) } else { $Tag = 'v1.0.0' }
  Write-Host "No -Tag given; using $Tag" -ForegroundColor Yellow
}
if ($Tag -notmatch '^v\d+\.\d+\.\d+([-.][0-9A-Za-z.-]+)?$') { throw "Invalid release tag: $Tag" }

$outDir = Split-Path $BoxPath -Parent
$sum = Join-Path $outDir 'SHA256SUMS'
$boxFile = Split-Path $BoxPath -Leaf
$hash = (Get-FileHash -Algorithm SHA256 $BoxPath).Hash.ToLowerInvariant()
"$hash  $boxFile" | Set-Content -Encoding ascii $sum

$repo = (gh repo view --json nameWithOwner --jq .nameWithOwner)
$url = "https://github.com/$repo/releases/download/$Tag/$boxFile"
$notes = @"
Hyper-V Vagrant box (Ubuntu 26.04.1 LTS) for k8s-hyperv-lab.

SHA256: ``$hash``

``````powershell
Invoke-WebRequest $url -OutFile $boxFile
vagrant box add $BoxName .\$boxFile
``````
"@

gh release view $Tag *> $null
if ($LASTEXITCODE -eq 0) {
  gh release upload $Tag $BoxPath $sum --clobber
} else {
  gh release create $Tag $BoxPath $sum --title "k8s-hyperv-lab $Tag" --notes $notes --generate-notes
}
if ($LASTEXITCODE -ne 0) { throw "gh release failed with exit code $LASTEXITCODE" }
Write-Host "Published ${Tag}: $url" -ForegroundColor Green

if ($Register) {
  vagrant box add $BoxName $BoxPath --force
  if ($LASTEXITCODE -ne 0) { throw "vagrant box add failed with exit code $LASTEXITCODE" }
}
