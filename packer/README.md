# Ubuntu 26.04.1 Hyper-V box

```powershell
packer init .
packer fmt -check -recursive .
packer validate .
packer build .
vagrant box add ubuntu2604-hyperv .\output\ubuntu-26.04.1-hyperv.box
```

The image contains only the base Ubuntu/Vagrant prerequisites. Kubernetes configuration is managed after VM creation.
