# Change Log


## [v0.2.0][] (2018-10-04)

- Bug Fixes:
  + update inventory path for ansible guest mode when vagrant == 2.1.5

- Tasks:
  + upgrade to target teracy-dev ">= 0.6.0-a4, < 0.7.0"

Details: https://github.com/teracyhq-incubator/teracy-dev-k8s/milestone/2?closed=1


## [v0.1.0][] (2018-08-25)


Initial release version which supports k8s cluster setup:

- support both ansible guest and host modes
- support to use `workspace/inventory` for ansible options
- support to override inventory options with teracy-dev config override mechanism
- add default config: enable `kubeconfig_localhost` and `kubectl_localhost`


Details: https://github.com/teracyhq-incubator/teracy-dev-k8s/milestone/1?closed=1


[v0.1.0]: https://github.com/teracyhq-incubator/teracy-dev-k8s/milestone/1?closed=1
[v0.2.0]: https://github.com/teracyhq-incubator/teracy-dev-k8s/milestone/2?closed=1
