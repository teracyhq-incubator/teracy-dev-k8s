# teracy-dev-k8s

Setting up k8s cluster on teracy-dev (v0.6) with kubespray.


## Requirements

- Install the latest vagrant and virtualbox versions
- Use with teracy-dev v0.6

## How to use

- Clone `teracy-dev` project:

```bash
$ cd ~/
$ git clone https://github.com/hoatle/teracy-dev.git k8s-dev
$ cd k8s-dev
$ git checkout tasks/v0.6.0
```


- And then create `~/k8s-dev/workspace/teracy-dev-entry/config_default.yaml` with the following content:

```yaml
teracy-dev:
  extensions:
    - _id: "entry-0"
      path:
        extension: teracy-dev-k8s
      location:
        git: https://github.com/hoatle/teracy-dev-k8s.git
        branch: develop
      require_version: ">= 0.1.0-SNAPSHOT"
      enabled: true
```

- Finally:

```bash
$ cd ~/k8s-dev
$ vagrant up
```

When ansible is reported that everything is ok, check it out:

```bash
$ cd ~/k8s-dev
$ vagrant ssh
$ kubectl cluster-info
$ kubectl version
$ kubectl get pods
```

If ansible is not running sucessfully, for example:

```bash
fatal: [k8s-01]: FAILED! => {"attempts": 5, "changed": false, "cmd": "/usr/local/bin/kubectl get secrets -o custom-columns=name:{.metadata.name} --no-headers | grep -m1 default-token", "delta": "0:00:00.190677", "end": "2018-07-26 15:30:33.207118", "msg": "non-zero return code", "rc": 1, "start": "2018-07-26 15:30:33.016441", "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []}

NO MORE HOSTS LEFT *************************************************************
  to retry, use: --limit @/vagrant/workspace/kubespray/cluster.retry

PLAY RECAP *********************************************************************
k8s-01                     : ok=354  changed=111  unreachable=0    failed=1

Ansible failed to complete successfully. Any error output should be
visible above. Please fix these errors and try again.
==> k8s-01: The previous process exited with exit code 1.
```

You can retry with `$ vagrant reload --provision`


## Ansible Options

By default, we copy the sample inventory from kubespray into `workspace/inventory` if not exists yet,
so you can configure ansible from the `workspace/inventory` directory.


## Accessing Kubernetes API

See: https://github.com/kubernetes-incubator/kubespray/blob/master/docs/getting-started.md#accessing-kubernetes-api

You should see the generated artifacts within the `kubespray/inventory/sample/artifacts`

You can append this config into the `~/.kube/config` file and use `kubectl` anywhere without specifying
the kubeconfig file:

```
$ cd workspace/inventory/artifacts/
$ cat admin.conf > ~/.kube/config # append the generated admin config to the config file
```

Use it:

```
$ kubectl config use-context admin-cluster.local
$ kubectl cluster-info
```


## Configuration Override

To override default config, you need to create `workspace/teracy-dev-entry/config_override.yaml` to
override the values from `teracy-dev-k8s/config_default.yaml`.

For example:

```yaml
teracy-dev-k8s:
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
