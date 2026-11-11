# Post-deployment validation

Use this runbook after the initial deployment, after restoring a Hyper-V checkpoint, or after making cluster/networking changes.

Expected component versions below match the pins in `ansible/inventory/group_vars/all.yml`; update this runbook when you change them.

## 1. Kubernetes nodes

From Windows PowerShell:

```powershell
kubectl get nodes -o wide
kubectl get pods -A -o wide
```

Verify:

- [ ] `control1`, `worker1`, and `worker2` are `Ready`.
- [ ] All nodes report Kubernetes `v1.37.1`.
- [ ] Node internal addresses are `192.168.77.11`, `.12`, and `.13`.
- [ ] System workloads are `Running` or `Completed`.

## 2. Calico

```powershell
kubectl get pods -n calico-system
kubectl get installations.operator.tigera.io
```

Verify:

- [ ] Calico node workloads are running.
- [ ] Calico controllers are running.
- [ ] The cluster remains `Ready` after CNI installation.

## 3. MetalLB

```powershell
kubectl get pods -n metallb-system
kubectl get ipaddresspools -n metallb-system
kubectl get l2advertisements -n metallb-system
```

Verify:

- [ ] MetalLB controller is running.
- [ ] MetalLB speaker DaemonSet is healthy.
- [ ] `kube-lab-pool` exists.
- [ ] The address range is `192.168.77.200-192.168.77.220`.
- [ ] `kube-lab-l2` exists.

## 4. Metrics Server

```powershell
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
kubectl top pods -A
```

Verify:

- [ ] Metrics Server is available.
- [ ] Node CPU and memory metrics are returned.
- [ ] Pod CPU and memory metrics are returned.

> Lab-only security note: Metrics Server uses `--kubelet-insecure-tls` in this disposable environment. Do not reuse this setting for production.

## 5. Gateway API

```powershell
kubectl get crd | Select-String "gateway.networking.k8s.io"
kubectl get gatewayclass
kubectl get gateways -A
kubectl get httproutes -A
```

Verify:

- [ ] Standard Gateway API CRDs are installed.
- [ ] A Traefik-managed GatewayClass is available.
- [ ] Gateway and HTTPRoute resources can be created and accepted.

## 6. Traefik and LoadBalancer addressing

```powershell
kubectl get pods -n traefik
kubectl get svc -n traefik -o wide
kubectl get gatewayclass
```

Verify:

- [ ] Traefik is running.
- [ ] The Traefik Service is type `LoadBalancer`.
- [ ] MetalLB assigns an external address from `192.168.77.200-192.168.77.220`.

## 7. North-south traffic

After deploying a test backend, Gateway, and HTTPRoute:

```powershell
kubectl get gateway,httproute -A
kubectl get svc -A
curl.exe http://<TRAEFIK-EXTERNAL-IP>
```

Expected traffic path:

```text
Windows client
  -> MetalLB external IP
  -> Traefik
  -> Gateway
  -> HTTPRoute
  -> Service
  -> Pod
```

Verify:

- [ ] Gateway reports an accepted/programmed condition.
- [ ] HTTPRoute is attached to the expected Gateway.
- [ ] The backend responds through the MetalLB external IP.


## Node troubleshooting tools and cgroups

On any node:

```bash
crictl version
crictl info
crictl pods
stat -fc %T /sys/fs/cgroup
```

Expected cgroup filesystem: `cgroup2fs`.

On `control1`:

```bash
etcdctl version
etcdutl version
containerd config dump | grep SystemdCgroup
```

Verify:

- [ ] `crictl` is v1.37.0 and talks to containerd.
- [ ] cgroup v2 is active.
- [ ] containerd reports `SystemdCgroup = true`.
- [ ] `etcdctl` and `etcdutl` are available on `control1`.

## 8. Automated validation

The deployment runs the validation playbook automatically. Re-run it from WSL when needed:

```bash
ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/validate-cluster.yml
```

## Final acceptance checklist

- [ ] Three Kubernetes nodes are `Ready`.
- [ ] Kubernetes version is `v1.37.1`.
- [ ] Calico is healthy.
- [ ] MetalLB is healthy and the L2 pool is configured.
- [ ] Metrics Server is healthy.
- [ ] `kubectl top nodes` works.
- [ ] Gateway API CRDs are installed.
- [ ] Traefik is healthy.
- [ ] Traefik receives a MetalLB address.
- [ ] Gateway/HTTPRoute traffic reaches a test workload.
- [ ] Windows kubeconfig works.

When all checks pass, the lab is ready for Kubernetes administration, NetworkPolicy, LoadBalancer Services, Gateway API, HPA, upgrades, and troubleshooting exercises.
