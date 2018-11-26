# Change Log


## [v0.3.0][] (2018-11-26)

- Improvements:
  + should update provisioner name so that we can call each provision with its name #36
  + should update SSO docs by using teracy-dev-certs #38
  + should update to the new location sync format #40
  + should move SUPPORTED_OS to config.yaml file instead #31
  + should have ansible install version for guest mode #47
  + should sync supported_oses with kubespray and check to make sure it works #43

- Tasks:
  + should upgrade kubespray to v2.7.0 #30
  + should add docs how to get SSO work with Dex #11


Details: https://github.com/teracyhq-incubator/teracy-dev-k8s/milestone/3?closed=1


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
[v0.3.0]: https://github.com/teracyhq-incubator/teracy-dev-k8s/milestone/3?closed=1

