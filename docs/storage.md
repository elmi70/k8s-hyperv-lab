# Storage

The lab installs [Rancher local-path-provisioner](https://github.com/rancher/local-path-provisioner) (version `local_path_provisioner_version` in `ansible/inventory/group_vars/all.yml`) and makes its `local-path` StorageClass the cluster default. PersistentVolumeClaims bind automatically, so you do not create PersistentVolumes by hand.

## How it behaves

- **Binding is delayed.** The StorageClass uses `WaitForFirstConsumer`, so a PVC stays `Pending` until a pod that uses it is scheduled. That is expected, not an error.
- **Node-local.** A volume is a directory on the node where its pod first ran (`/opt/local-path-provisioner/...` on that VM). Pods that use it are pinned to that node, so a pod cannot move to another node and keep its data.
- **`ReadWriteOnce` only.** `ReadWriteMany` is not supported.
- **Deleted with the PVC.** The reclaim policy is `Delete`: deleting the PVC removes the data.
- **Tied to the VM disk.** The data is removed when the VMs are destroyed, but Hyper-V checkpoints (`Save-K8sSnapshot.ps1`) capture it.
- **Not a real storage system.** There is no replication or failover. For Ceph-style storage you would need extra disks and more RAM than the default lab has.

## Example

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: demo
spec:
  containers:
    - name: app
      image: docker.io/library/busybox:1.36
      command: ["sh", "-c", "echo hello > /data/hello && sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: demo
```

```powershell
kubectl apply -f demo.yaml
kubectl get pvc demo        # Pending until the pod is scheduled, then Bound
kubectl get pv
kubectl delete -f demo.yaml # the PV and its data are removed with the PVC
```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| PVC stays `Pending` with no pod using it | `WaitForFirstConsumer` | Create the pod; the PVC binds when it is scheduled. |
| PVC `Pending` even with a pod | Provisioner not running or image pull failing | `kubectl -n local-path-storage get pods` and `kubectl -n local-path-storage logs deploy/local-path-provisioner`. |
| PVC has no StorageClass | Default class annotation missing | `kubectl get storageclass` should show `local-path (default)`; re-run `install-local-path.yml`. |
