param([Parameter(Mandatory=$true)][string]$Tag,[string]$BoxPath="$(Split-Path $PSScriptRoot -Parent)\packer\output\ubuntu-26.04.1-hyperv.box")
$ErrorActionPreference='Stop'
if(-not(Get-Command gh -ErrorAction SilentlyContinue)){throw 'GitHub CLI (gh) is required.'}
if(-not(Test-Path $BoxPath)){throw "Box not found: $BoxPath"}
if($Tag -notmatch '^v\d+\.\d+\.\d+([-.][0-9A-Za-z.-]+)?$'){throw "Invalid release tag: $Tag"}
$outDir=Split-Path $BoxPath -Parent
$sum=Join-Path $outDir 'SHA256SUMS'
$hash=(Get-FileHash -Algorithm SHA256 $BoxPath).Hash.ToLowerInvariant()
"$hash  $(Split-Path $BoxPath -Leaf)" | Set-Content -Encoding ascii $sum
gh release view $Tag *> $null
if($LASTEXITCODE -eq 0){ gh release upload $Tag $BoxPath $sum --clobber } else { gh release create $Tag $BoxPath $sum --generate-notes --title "k8s-hyperv-lab $Tag" }
