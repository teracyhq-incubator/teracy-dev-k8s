# Rook Storage Service

This guide will help you to create a high-availability (HA) and scalable storage system to run pods.

Rook provides HA and scalable cloud native storage service for a k8s cluster so that the pods can
consume.

## Rook operator deployment

- Set the VM RAM to be 4GB is recommended via the `teracy-dev-entry/config_override.yaml` file, for
example:

```yaml
teracy-dev-k8s:
  vm_memory: 4000
```


- From https://rook.io/docs/rook/v0.8/helm-operator.html:

  + Make sure to identify the `kubelet_flexvolumes_plugins_dir`, it is
    `/var/lib/kubelet/volume-plugins` by default on kubespray.

  + Set the `agent.flexVolumeDirPath` key to the right value:

  ```bash
  $ helm install --namespace rook-ceph-system rook-beta/rook-ceph --set=agent.flexVolumeDirPath=/var/lib/kubelet/volume-plugins
  ```

- Just need to make sure to set the the right value for `flexVolumeDirPath` and follow the Rook docs
as is.

## rook-ceph-block storage class

- Follow https://rook.io/docs/rook/v0.8/block.html

- When `rook-ceph-block` storageclass is available, it can be used with the [mysql-operator][] cluster,
for example:

```yaml
apiVersion: mysql.oracle.com/v1alpha1
kind: Cluster
metadata:
  name: my-app-db
  namespace: test
spec:
  members: 3
  volumeClaimTemplate:
    metadata:
      name: data
    spec:
      storageClassName: rook-ceph-block
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
```

## ReadWriteMany (RWX) access mode volume

- Follow: https://rook.io/docs/rook/master/nfs.html

By using the `rook-ceph-block` storageclass and NFS for `RWX` access mode volume, HA and
scalablility of pods can be achieved, especially with stateful applications.


## References

- https://rook.io
- https://github.com/operator-framework/awesome-operators
- https://commons.openshift.org/sig/operators.html

[mysql-operator]: https://github.com/oracle/mysql-operator
