# teracy-dev-k8s

Setting up k8s cluster on teracy-dev (v0.6) with kubespray for a production ready local k8s cluster.
This can be considered a local managed k8s service that we can use it for testing, it should work
the same way as any k8s cluster in the cloud.


## How to use

Configure `workspace/teracy-dev-entry/config_default.yaml` with the following similar content:

- Use specific version:

```yaml
teracy-dev:
  extensions:
    - _id: "entry-0" # this _id is used for overriding by the config_override.yaml file
      path:
        extension: teracy-dev-k8s
      location:
        git: https://github.com/teracyhq-incubator/teracy-dev-k8s.git
        branch: v0.2.0
      require_version: ">= 0.2.0, < 0.3.0"
      enabled: true
```

- Use latest stable version (auto update):

```yaml
teracy-dev:
  extensions:
    - _id: "entry-0" # this _id is used for overriding by the config_override.yaml file
      path:
        extension: teracy-dev-k8s
      location:
        git: https://github.com/teracyhq-incubator/teracy-dev-k8s.git
        branch: master
      require_version: ">= 0.2.0, < 0.3.0"
      enabled: true
```


- Use latest develop version (auto update):

```yaml
teracy-dev:
  extensions:
    - _id: "entry-0" # this _id is used for overriding by the config_override.yaml file
      path:
        extension: teracy-dev-k8s
      location:
        git: https://github.com/teracyhq-incubator/teracy-dev-k8s.git
        branch: develop
      require_version: ">= 0.3.0-SNAPSHOT"
      enabled: true
```


See this example setup: https://github.com/teracyhq-incubator/teracy-dev-entry-k8s#how-to-use

## Vagrant Reload

Whenever the node(s) is reloaded, make sure to provision it so that the k8s cluster is working properly

```
$ vagrant halt
$ vagrant up --provision
```

```
$ vagrant reload --provision
```


## Ansible Options

By default, we copy the sample inventory from kubespray into `workspace/inventory` if not exists yet,
so you can configure ansible from the `workspace/inventory` directory.

Moreover, you can also override inventory options with `teracy-dev-k8s['ansible']['host_vars']`,
see the configuration override section below


## Accessing Kubernetes API

You should see the generated artifacts within the `workspace/inventory/artifacts` directory

By default, the `admin.conf`, `kubectl` and `kubectl.sh` files are generated.

You can use:

```
$ cd workspace/inventory/artifacts
$ ./kubectl.sh cluster-info
```

You can copy the `kubectl` file to your local bin (`/usr/local/bin/`) or better to install it
yourself with autocomplete.


And then set the `KUBECONFIG` env var for `kubectl` to work:

```
$ cd workspace/inventory/artifacts
$ export KUBECONFIG=$(pwd)/admin.conf
$ # or if you want to use existing config
$ export KUBECONFIG=$KUBE_CONFIG:$(pwd)/admin.conf
$ # or
$ export KUBECONFIG=$HOME/.kube/config:$(pwd)/admin.conf
```

You can adjust the above script for `~/.bash_profile` so that it's loaded everytime a terminal session is started.

Use it:

```
$ kubectl config use-context admin-cluster.local
$ kubectl cluster-info
```

See:
- https://github.com/kubernetes-incubator/kubespray/blob/master/docs/getting-started.md#accessing-kubernetes-api
- https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

## Configuration Override

To override default config, you need to create `workspace/teracy-dev-entry/config_override.yaml` to
override the values from `teracy-dev-k8s/config.yaml`.

For example:

```yaml
teracy-dev-k8s:
  ansible:
    mode: host
    verbose: vv
    host_vars:
      kubectl_localhost: "False"
      helm_enabled: "True"
  vm_memory: 1600
  vm_cpus: 4
  num_instances: 3
```


## How to develop

Configure `workspace/teracy-dev-entry/config_override.yaml` with the following similar content:


```yaml
teracy-dev:
  extensions:
    - _id: "entry-0" # make sure the right _id matching from the config_default.yaml file
      path:
        lookup: workspace
      location:
        git: git@github.com:hoatle/teracy-dev-k8s.git # your forked repo
        branch: develop
      require_version: ">= 0.3.0-SNAPSHOT"
```


Enjoy and happy hacking!
