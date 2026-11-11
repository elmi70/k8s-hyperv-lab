param(
  [string]$WslDistribution = 'Ubuntu-26.04',
  [string]$OutputPath = "$(Split-Path $PSScriptRoot -Parent)\ansible\inventory\hosts.yml"
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$vagrantDir=Join-Path $root 'vagrant'
$labIps=@{control1='192.168.77.11';worker1='192.168.77.12';worker2='192.168.77.13'}
function Convert-ToWslPath([string]$Path) {
  $result = wsl.exe -d $WslDistribution -- wslpath -a $Path
  if($LASTEXITCODE -ne 0){throw "Could not convert path for WSL: $Path"}
  return ($result | Select-Object -First 1).Trim()
}
$hosts=@{}
Push-Location $vagrantDir
try {
  foreach($node in $labIps.Keys) {
    $raw = vagrant ssh-config $node
    if($LASTEXITCODE -ne 0){throw "vagrant ssh-config failed for $node"}
    $kv=@{}
    foreach($line in $raw){if($line -match '^\s*(\S+)\s+(.+)$'){$kv[$matches[1]]=$matches[2].Trim('"')}}
    $hosts[$node]=@{
      HostName=$kv['HostName']; Port=$kv['Port']; User=$kv['User']
      IdentityFile=(Convert-ToWslPath $kv['IdentityFile']); LabIp=$labIps[$node]
    }
  }
} finally { Pop-Location }
$lines=@('all:','  vars:','    ansible_python_interpreter: /usr/bin/python3','    ansible_ssh_common_args: "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"','  children:','    control_plane:','      hosts:')
foreach($node in @('control1')){$h=$hosts[$node];$lines += "        ${node}:"; $lines += "          ansible_host: $($h.HostName)"; $lines += "          ansible_port: $($h.Port)"; $lines += "          ansible_user: $($h.User)"; $lines += "          ansible_ssh_private_key_file: $($h.IdentityFile)"; $lines += "          lab_ip: $($h.LabIp)"}
$lines += @('    workers:','      hosts:')
foreach($node in @('worker1','worker2')){$h=$hosts[$node];$lines += "        ${node}:"; $lines += "          ansible_host: $($h.HostName)"; $lines += "          ansible_port: $($h.Port)"; $lines += "          ansible_user: $($h.User)"; $lines += "          ansible_ssh_private_key_file: $($h.IdentityFile)"; $lines += "          lab_ip: $($h.LabIp)"}
$lines += @('    k8s_nodes:','      children:','        control_plane:','        workers:')
$lines | Set-Content -Path $OutputPath -Encoding utf8
Write-Host "Generated Ansible inventory: $OutputPath"
