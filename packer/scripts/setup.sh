#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y ca-certificates curl openssh-server
sudo systemctl enable --now ssh

# Clean up so every VM cloned from this box gets its own identity and the box stays small.
sudo apt-get clean
# Empty machine-id is regenerated on first boot; without this all VMs share one id
# (which can lead to duplicate DHCP leases).
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
# Discard unused blocks so the exported disk compacts well (ignored if unsupported).
sudo fstrim -av || true
