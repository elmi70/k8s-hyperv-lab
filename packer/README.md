# Ubuntu 26.04.1 Hyper-V box

```powershell
packer init .
packer fmt -check -recursive .
packer validate .
packer build -force .
vagrant box add ubuntu2604-hyperv .\output\ubuntu-26.04.1-hyperv.box
```

The image contains only the base Ubuntu/Vagrant prerequisites. Kubernetes configuration is managed after VM creation.

## Credentials baked into the box

This is a disposable lab image, not a hardened one:

- User `vagrant` with password `vagrant` (SHA-512 hash in `autoinstall/user-data`; regenerate with `openssl passwd -6 -salt 'rounds=4096$VagrantLab' 'vagrant'`) and passwordless sudo. Packer connects with this password.
- Vagrant's well-known insecure public keys are in the user's `authorized_keys`. The Vagrantfile sets `insert_key = false`, so Vagrant keeps using them.

Do not use this image outside a local lab.

## After the install

The installer reboots into the installed system (no `shutdown:` key in the autoinstall) so Packer can reach it over SSH; Packer powers the VM off itself. `scripts/setup.sh` empties `/etc/machine-id` (each cloned VM generates its own) and trims unused blocks.

## First-build checks

Vagrant learns a Hyper-V VM's IP address through the Hyper-V KVP daemon. After the first build, boot a VM from the box and confirm it is running:

```bash
systemctl status hv-kvp-daemon     # or: systemctl status hv-kvp-daemon.service
```

If it is missing, add `linux-cloud-tools-virtual` and `linux-tools-virtual` (matching the running kernel) to `scripts/setup.sh` and rebuild; otherwise `vagrant up` will wait forever for the guest IP.
