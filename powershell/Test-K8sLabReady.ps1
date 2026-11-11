#Requires -RunAsAdministrator
$checks=@()
$checks += [pscustomobject]@{Check='vmms';Pass=((Get-Service vmms -ErrorAction SilentlyContinue).Status -eq 'Running')}
foreach($cmd in 'git','gh','packer','vagrant','kubectl','wsl'){ $checks += [pscustomobject]@{Check=$cmd;Pass=[bool](Get-Command $cmd -ErrorAction SilentlyContinue)} }
$checks += [pscustomobject]@{Check='k8s-lab switch';Pass=[bool](Get-VMSwitch -Name 'kube-lab-net' -ErrorAction SilentlyContinue)}
$checks | Format-Table -AutoSize
if($checks.Pass -contains $false){ exit 1 }
