function Get-K8sLabVM { Get-VM -Name 'k8s-lab-*' -ErrorAction SilentlyContinue }
function Assert-K8sLabVMCount { $v=Get-K8sLabVM; if($v.Count -ne 3){throw "Expected 3 lab VMs; found $($v.Count)."}; $v }
Export-ModuleMember -Function Get-K8sLabVM,Assert-K8sLabVMCount
