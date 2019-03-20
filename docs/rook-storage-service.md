# Rook Storage Service

This guide will help you to create a high-availability (HA) and scalable storage system to run pods.

Rook provides HA and scalable cloud native storage service for a k8s cluster so that the pods can
consume.

## Rook operator deployment

- Set the VM RAM to be 4GB (recommended) via the `teracy-dev-entry/config_override.yaml` file, for
example:

```yaml
teracy-dev-k8s:
  vm_memory: 4000
```


- From https://rook.io/docs/rook/v0.9/helm-operator.html:

  + Make sure to identify the `kubelet_flexvolumes_plugins_dir`, it is
    `/var/lib/kubelet/volume-plugins` by default on kubespray.

  + Set the `agent.flexVolumeDirPath` key to the right value:

  ```bash
  $ helm repo add rook-stable https://charts.rook.io/stable
  $ helm install --namespace rook-ceph-system rook-stable/rook-ceph --set=agent.flexVolumeDirPath=/var/lib/kubelet/volume-plugins
  ```

- Just need to make sure to set the right value for `flexVolumeDirPath` and follow the Rook docs.

- Wait for a while and you should see the following similar output:

```bash
$ kubectl -n rook-ceph-system get pods
NAME                                READY   STATUS    RESTARTS   AGE
rook-ceph-agent-x6wbl               1/1     Running   4          1h
rook-ceph-operator-999786ff-mpb4k   1/1     Running   3          1h
rook-discover-mm5hr                 1/1     Running   3          1h
```

## Create a cluster

- Execute the commands below:

  ```bash
  $ cd docs/rook
  $ kubectl apply -f cluster.yaml
  ```

- Wait for a while and you should see the similar output below:

```bash
$ kubectl -n rook-ceph get pods
NAME                                 READY   STATUS      RESTARTS   AGE
rook-ceph-mgr-a-56d5cbc754-mgmjn     1/1     Running     2          1h
rook-ceph-mon-a-8485c65dff-5hlcl     1/1     Running     2          1h
rook-ceph-mon-b-5f4976db99-6wrf8     1/1     Running     2          1h
rook-ceph-mon-c-8b4db4d-w2n2s        1/1     Running     2          1h
rook-ceph-osd-0-846db55997-2m8mw     1/1     Running     2          1h
rook-ceph-osd-prepare-k8s-01-g48m9   0/2     Completed   0          1h
```

## rook-ceph-block storage class

- Execute the following command:

  ```bash
  $ cd docs/rook
  $ kubectl apply -f storageclass.yaml
  ```

- You should see the following output:

```bash
$ kubectl get storageclasses.storage.k8s.io
NAME                        PROVISIONER          AGE
rook-ceph-block (default)   ceph.rook.io/block   1h
```

## ReadWriteMany (RWX) access mode volume

- Follow: https://rook.io/docs/rook/v0.9/nfs.html

By using the `rook-ceph-block` storageclass and NFS for `RWX` access mode volume, HA and
scalablility of pods can be achieved, especially with stateful applications.


## References

- https://rook.io
- https://github.com/operator-framework/awesome-operators
- https://commons.openshift.org/sig/operators.html
