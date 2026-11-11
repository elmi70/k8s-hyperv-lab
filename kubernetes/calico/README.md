# Calico

Calico 3.33.0 is the lab CNI, providing pod networking and NetworkPolicy. The lab uses the Tigera Operator and a VXLAN pool matching `10.244.0.0/16`.

The Calico version (`calico_version`) and the pod CIDR (`pod_cidr`) are defined in `ansible/inventory/group_vars/all.yml`. The `cidr` in `installation.yaml` must equal `pod_cidr`; the CNI playbook fails before installing anything if it does not.
