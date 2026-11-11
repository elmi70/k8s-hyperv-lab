# Calico

Calico 3.33.0 is the lab CNI, providing pod networking and NetworkPolicy. The lab uses the Tigera Operator and a VXLAN pool matching `10.244.0.0/16`.

The Calico version (`calico_version`), the pod CIDR (`pod_cidr`) and the lab network (`lab_cidr`) are defined in `ansible/inventory/group_vars/all.yml`. The `cidr` in `installation.yaml` must equal `pod_cidr`, and `nodeAddressAutodetectionV4` must use `lab_cidr` so Calico uses the lab NIC (the same address kubelet advertises) rather than the Default Switch management NIC. The CNI playbook fails before installing anything if either does not match.

The CRDs and operator are applied with `kubectl apply --server-side` because they are too large for client-side apply.
