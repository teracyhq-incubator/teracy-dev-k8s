# Docker Daemon Remote Access

Similar to this https://kubernetes.io/docs/setup/minikube/#use-local-images-by-re-using-the-docker-daemon,
it is useful in some circumstances. You can follow this guide to enable remote access from
the host machine docker client to the VM docker daemon.


## Add dockerd options

You can add the `-H` dockerd options via ansible configuration in the `teracy-dev-entry/config_override.yaml`
file with the following configuration:

```yaml
teracy-dev-k8s:
  ansible:
    host_vars:
      # workaround for TCP remote access to docker daemon from the host to the VM
      docker_log_opts: "-H fd:// -H tcp://0.0.0.0:2375 --log-opt max-size=50m --log-opt max-file=5"
```

and then `$ vagrant reload --provision` to get that configuration take effect.


## Access the remote docker daemon

```bash
$ docker -H tcp://k8s.local:2375 ps
```

or

```bash
$ export DOCKER_HOST="tcp://k8s.local:2375"
$ docker ps
```

Note: `k8s.local` is the default domain alias to the remote VM, you can use any domain alias or use the remote
VM's IP address.


## References

- https://kubernetes.io/docs/setup/minikube/#use-local-images-by-re-using-the-docker-daemon
- https://docs.docker.com/engine/reference/commandline/dockerd/
