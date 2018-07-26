# teracy-dev-k8s

Setting up k8s cluster on teracy-dev (v0.6) with kubespray.


## Requirements

- Install the latest vagrant and virtualbox versions
- Use with teracy-dev v0.6

## How to use

- Clone `teracy-dev`, `kubespray` and `teracy-dev-k8s` projects

```bash
$ cd ~/
$ git clone git@github.com:hoatle/teracy-dev.git k8s-dev
$ cd k8s-dev
$ git checkout tasks/v0.6.0
$ cd workspace
$ git clone https://github.com/kubernetes-incubator/kubespray.git
$ git clone git@github.com:hoatle/teracy-dev-k8s.git
```


- And then create `~/k8s-dev/workspace/dev-setup/config_default.yaml` with the following content:

```yaml
teracy-dev:
  extensions:
    - path: workspace/teracy-dev-k8s
      require_version: ">= 0.1.0-SNAPSHOT"
      required: true
```

- Finally:

```bash
$ cd ~/k8s-dev
$ vagrant up
```


When ansible is reported that everything is ok, check it:

```bash
$ cd ~/k8s-dev
$ vagrant ssh
$ kubectl cluster-info
$ kubectl version
$ kubectl get pods
```


## Configuration Override

To override default config, you need to create `workspace/teracy-dev-k8s/config_override.yaml` to
override the values from `workspace/teracy-dev-k8s/config_default.yaml`.

For example:

```yaml
k8s:
  num_instances: 2
```


Enjoy and happy hacking!
