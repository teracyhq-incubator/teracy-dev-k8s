# Docker Registry

This guide will help you to create a docker registry in a k8s cluster.


## Prerequisites

- a k8s cluster available by following https://github.com/teracyhq-incubator/teracy-dev-entry-k8s#how-to-use

- [Rook storage service](rook-storage-service.md) to set up rook-ceph-block storage class by
  following https://rook.io/docs/rook/v0.8/block.html#provision-storage

- [cert-manager](cert-manager.md) to set up a CA cluster issuer


## Enable docker registry

- Set the ansible host variables within the `workspace/teracy-dev-entry/config_override.yaml` file:


```yaml
teracy-dev-k8s:
  ansible:
    host_vars:
      registry_enabled: true
      registry_namespace: "docker-registry"
      registry_storage_class: "rook-ceph-block"
      registry_disk_size: "5Gi"
```

- Then `$ vagrant reload --provision` to get it the docker registry installed.

- To confirm, you should see the following similar output:

```bash
$ kubectl -n docker-registry get pods
NAME                   READY   STATUS    RESTARTS   AGE
registry-proxy-2g4x8   1/1     Running   6          13h
registry-rp2rt         1/1     Running   4          13h
```

## Create an ingress host


- Create a k8s ingress resource from the `docs/docker-registry/ingress.yaml` file:

```bash
$ cd docs/docker-registry
$ kubectl apply -f ingress.yaml
ingress.extensions/docker-registry created
```

## Access the ingress host

- We need to create the domain alias of `registry.k8s.local` to point to the k8s master's IP by editing
the `workspace/teracy-dev-entry/config_override.yaml` with the following configuration:


```yaml
nodes:
  - _id: "0"
    plugins:
      - _id: "entry-hostmanager"
        options:
          _ua_aliases: # set domain aliases for the master node
            - registry.k8s.local
```

- Then `$ vagrant hostmanager` to get the `hosts` file updated in the host and the guest machines.


- Make sure to trust the root CA certificate:

  + From the host machine, follow https://github.com/teracyhq-incubator/teracy-dev-certs#how-to-trust-the-self-signed-ca-certificate

  + From the guest machine, execute the following commands:

  ```bash
  $ vagrant ssh
  $ sudo cp /vagrant/workspace/certs/k8s-local-ca.crt /usr/local/share/ca-certificates/
  $ sudo update-ca-certificates
  $ sudo service docker restart
  ```

## Verify from your host machine

- To verify that it works from your host machine, make sure `docker` is installed and running:

```bash
$ docker image pull alpine:latest
$ docker image tag alpine:latest registry.k8s.local/alpine:latest
$ docker image push registry.k8s.local/alpine:latest
The push refers to repository [registry.k8s.local/alpine]
503e53e365f3: Pushed
latest: digest: sha256:25b4d910f4b76a63a3b45d0f69a57c34157500faf6087236581eca221c62d214 size: 528
$ docker image pull registry.k8s.local/alpine:latest
latest: Pulling from alpine
Digest: sha256:d05ecd4520cab5d9e5d877595fb0532aadcd6c90f4bbc837bc11679f704c4c82
Status: Image is up to date for registry.k8s.local/alpine:latest
```

- Notes on Windows:

  + Docker for Windows (requires Hyper-V enabled) and the k8s cluster with Virtualbox on Windows
    (requires Hyper-V disabled) will not work at the same time so we need to run these 2 separately
    on 2 machines.
  + We can use registry.xxx.xip.io, registry.xxx.nip.io domains by updating the ingress.yaml file
    accordingly) or the hosts file to map the registry.k8s.local domain with the remote
    k8s-cluster's IP address.


## Verify from your guest machine

- To verify that it works from your guest machine:

```bash
$ cd ~/k8s-dev
$ vagrant ssh
$ sudo docker image pull alpine:latest
$ sudo docker image tag alpine:latest registry.k8s.local/alpine:latest
$ sudo docker image push registry.k8s.local/alpine:latest
The push refers to repository [registry.k8s.local/alpine]
503e53e365f3: Pushed
latest: digest: sha256:25b4d910f4b76a63a3b45d0f69a57c34157500faf6087236581eca221c62d214 size: 528
$ docker image pull registry.k8s.local/alpine:latest
latest: Pulling from alpine
Digest: sha256:d05ecd4520cab5d9e5d877595fb0532aadcd6c90f4bbc837bc11679f704c4c82
Status: Image is up to date for registry.k8s.local/alpine:latest
```


## Enable SSO

// TODO(phuonglm): https://github.com/teracyhq-incubator/teracy-dev-k8s/issues/34


## References

- https://github.com/kubernetes-sigs/kubespray/tree/master/roles/kubernetes-apps/registry
