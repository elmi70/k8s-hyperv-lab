#!/usr/bin/env bash
# Assign the static lab IP to the second NIC (attached to kube-lab-net).
# The first NIC (default route, Hyper-V Default Switch) stays on DHCP for management.
set -euo pipefail

LAB_IP="${1:?usage: configure-lab-nic.sh <ip>}"
PREFIX=24

default_nic() { ip -4 route show default | awk '{print $5; exit}'; }
lab_nic() {
  local def n
  def="$(default_nic)"
  for n in /sys/class/net/*; do
    n="${n##*/}"
    if [ "$n" != "lo" ] && [ "$n" != "$def" ]; then
      echo "$n"
      return 0
    fi
  done
  return 0
}

# The NIC is hot-added by Add-K8sLabNic.ps1; give the guest a moment to see it.
NIC=""
for _ in $(seq 1 30); do
  NIC="$(lab_nic)"
  [ -n "$NIC" ] && break
  sleep 1
done
[ -n "$NIC" ] || { echo "No second NIC found. Run powershell/Add-K8sLabNic.ps1 first." >&2; exit 1; }

MAC="$(cat "/sys/class/net/${NIC}/address")"

sudo tee /etc/netplan/60-k8s-lab.yaml >/dev/null <<EOF
network:
  version: 2
  ethernets:
    # systemd-networkd applies only the first matching .network file, in name order. The box
    # ships a catch-all DHCP rule (id "all-en", matching e*) that would also match this NIC.
    # This id must sort before "all-en" so the static lab address wins.
    a0-k8slab:
      match:
        macaddress: "${MAC}"
      dhcp4: false
      dhcp6: false
      addresses:
        - ${LAB_IP}/${PREFIX}
EOF
sudo chmod 600 /etc/netplan/60-k8s-lab.yaml
sudo netplan apply

ip -4 -o addr show | grep -q " ${LAB_IP}/" || { echo "Failed to configure ${LAB_IP}" >&2; exit 1; }
echo "Configured ${LAB_IP}/${PREFIX} on ${NIC} (${MAC})"
