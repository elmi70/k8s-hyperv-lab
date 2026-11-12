#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y ca-certificates curl openssh-server
sudo systemctl enable --now ssh

# Shrink the image (GitHub Releases allows files under 2 GiB). The installer ships a full server
# image; a disposable Hyper-V lab node does not need snap, hardware firmware (Hyper-V uses
# paravirtual devices) or kdump, and none of the playbooks use them.
if command -v snap >/dev/null 2>&1; then
  # Two passes: a base snap (core24) cannot be removed until the snaps that use it are gone.
  for _ in 1 2; do
    while read -r name; do
      sudo snap remove --purge "$name" || true
    done < <(snap list 2>/dev/null | awk 'NR > 1 && $1 != "snapd" {print $1}')
  done
  sudo snap remove --purge snapd || true
fi
sudo apt-get purge -y snapd linux-firmware kdump-tools kexec-tools makedumpfile || true
sudo rm -rf /var/lib/snapd /var/snap /snap /var/crash
# Also drop packages the installer leaves behind (older kernel, headers, ZFS modules, tools).
# apt never removes the running kernel, and the checks below fail the build if the result is
# not bootable.
sudo apt-get autoremove --purge -y

# Guard: the box must still have a kernel, an initramfs and the Hyper-V KVP daemon package
# (without KVP, Packer and Vagrant never learn the guest IP).
compgen -G '/boot/vmlinuz-*' >/dev/null && compgen -G '/boot/initrd.img-*' >/dev/null
sudo test -e /boot/vmlinuz && sudo test -e /boot/initrd.img
dpkg -s linux-cloud-tools-virtual >/dev/null

# Clean up so every VM cloned from this box gets its own identity and the box stays small.
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo journalctl --rotate >/dev/null 2>&1 || true
sudo journalctl --vacuum-size=1M >/dev/null 2>&1 || true
# Empty machine-id is regenerated on first boot; without this all VMs share one id
# (which can lead to duplicate DHCP leases).
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

# The installer creates /swap.img (several GiB). Kubernetes requires swap off (the prerequisites
# playbook disables it), so remove it here instead of shipping it inside every VM disk.
echo "--- swap before removal:"
swapon --show || true
ls -lh /swap.img 2>/dev/null || true
sudo swapoff -a || true
sudo sed -i '\|/swap.img|d' /etc/fstab
sudo rm -f /swap.img

# Report what is left, so the next size reduction is based on data (shown in the Packer log).
# -a lists individual files too; plain "du --max-depth" hides files such as /swap.img.
echo "--- disk usage after cleanup:"
df -h / || true
sudo du -axh / 2>/dev/null | sort -rh | head -25 || true

# Discard unused blocks so the exported disk compacts well (ignored if unsupported).
sudo fstrim -av || true
