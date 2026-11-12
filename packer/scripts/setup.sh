#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y ca-certificates curl openssh-server
sudo systemctl enable --now ssh

# Clean up so every VM cloned from this box gets its own identity and the box stays small.
# Drop packages the installer leaves behind (older kernel, headers, ZFS modules, tools). apt never
# removes the running kernel, so this is safe, and it shrinks the box (GitHub Releases limit: 2 GiB).
sudo apt-get autoremove --purge -y
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
# Empty machine-id is regenerated on first boot; without this all VMs share one id
# (which can lead to duplicate DHCP leases).
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
# Discard unused blocks so the exported disk compacts well (ignored if unsupported).
sudo fstrim -av || true
