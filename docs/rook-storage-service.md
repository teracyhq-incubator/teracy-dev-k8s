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


- From https://rook.io/docs/rook/v1.0/helm-operator.html:

  + Make sure to identify the `kubelet_flexvolumes_plugins_dir`, it is
    `/var/lib/kubelet/volume-plugins` by default on kubespray.

  + Set the `agent.flexVolumeDirPath` key to the right value:

  ```bash
  $ helm repo add rook-release https://charts.rook.io/release
  $ helm install --namespace rook-ceph rook-release/rook-ceph --set=agent.flexVolumeDirPath=/var/lib/kubelet/volume-plugins
  ```

- Just need to make sure to set the right value for `flexVolumeDirPath` and follow the Rook docs.

- Wait for a while and you should see the following similar output:

  ```bash
  $ kubectl -n rook-ceph get pods
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
  NAME                                  READY   STATUS      RESTARTS   AGE
  rook-ceph-agent-9t8m9                 1/1     Running     0          6m
  rook-ceph-mgr-a-779b5fd5c4-s86sm      1/1     Running     0          2m
  rook-ceph-mon-a-fd5f596c-wxw2x        1/1     Running     0          3m
  rook-ceph-mon-b-5484c5b6d7-4xqgp      1/1     Running     0          3m
  rook-ceph-mon-c-746f464b4c-z8hx8      1/1     Running     0          3m
  rook-ceph-operator-577ff88877-w56wl   1/1     Running     0          7m
  rook-ceph-osd-0-6b789c4cb6-gmcr9      1/1     Running     0          3m
  rook-ceph-osd-prepare-k8s-01-sdwnc    0/2     Completed   0          2m
  rook-discover-lswfr                   1/1     Running     0          6m
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

- Follow: https://rook.io/docs/rook/v1.0/nfs.html

By using the `rook-ceph-block` storageclass and NFS for `RWX` access mode volume, HA and
scalablility of pods can be achieved, especially with stateful applications.


- Deploy the Rook NFS operator using the following commands:

  ```bash
  $ cd docs/rook
  $ kubectl apply -f nfs-operator.yaml
  ```

- Check if the operator is up and running with:

  ```bash
  $ kubectl -n rook-nfs-system get pod
  NAME                                    READY   STATUS    RESTARTS   AGE
  rook-nfs-operator-b8d6d955d-gmcr9       1/1     Running   0          1m
  rook-nfs-provisioner-848bc947d5-dspfc   1/1     Running   0          1m
  ```


## References

- https://rook.io
- https://github.com/operator-framework/awesome-operators
- https://commons.openshift.org/sig/operators.html
