# teracy-dev-k8s

Setting up k8s cluster on teracy-dev (v0.6) with kubespray for a production ready local k8s cluster.
This can be considered a local managed k8s service that we can use it for testing, it should work
the same as any k8s cluster in the cloud.


## How to use

Configure `workspace/teracy-dev-entry/config_default.yaml` with the following similar content:

```yaml
teracy-dev:
  extensions:
    - _id: "entry-0"
      path:
        extension: teracy-dev-k8s
      location:
        git: https://github.com/teracyhq-incubator/teracy-dev-k8s.git
        branch: develop
      require_version: ">= 0.1.0-SNAPSHOT"
      enabled: true
```


See this example setup: https://github.com/teracyhq-incubator/teracy-dev-entry-k8s#how-to-use


## Ansible Options

By default, we copy the sample inventory from kubespray into `workspace/inventory` if not exists yet,
so you can configure ansible from the `workspace/inventory` directory.


## Configuration Override

To override default config, you need to create `workspace/teracy-dev-entry/config_override.yaml` to
override the values from `teracy-dev-k8s/config_default.yaml`.

For example:

```yaml
teracy-dev-k8s:
  ansible:
    mode: host
    verbose: vv
  vm_memory: 1600
  vm_cpus: 4
  num_instances: 3
```


## How to develop

Configure `workspace/teracy-dev-entry/config_override.yaml` with the follow similar content:

- Configure as follows:

```yaml
teracy-dev:
  extensions:
    - _id: "entry-0"
      path:
        lookup: workspace
      location:
        git: git@github.com:hoatle/teracy-dev-k8s.git # your forked repo
```


Enjoy and happy hacking!
