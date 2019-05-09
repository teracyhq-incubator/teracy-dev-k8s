This page shows you how to install kubectl and helm on macOS, Linux (Ubuntu) and Windows. Also this guide instructs you the way to enable shell autocompletion.

___

# Menu

- Install `kubectl` for each OS you need:
	+ [Mac Os](#kubectl_mac_os)
	+ [Linux(Ubuntu)](#kubectl_linux)
	+ [Windows](#kubectl_windows)

- Install `helm` for each OS you need:
	+ [Mac Os](#helm_mac_os)
	+ [Linux(Ubuntu)](#helm_linux)
	+ [Windows](#helm_windows)

# Kubectl
``kubectl`` is the Kubernetes command line tool, which can be used to deploy settings to the cluster.
In this section, you should know how to install kubectl.

## <a name="kubectl_mac_os"></a>Mac Os

### Install

- Latest version:

	+ follow the official documentation at https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-macos.

- Downgrading or upgrading version:

	+ If you have ever installed the desired version with `homebrew`, you can swich to that version.

	```bash
	$ brew info kubernetes-cli
	$ brew switch kubernetes-cli 1.12.0 # example downgrade to version 1.12.0
	```

	+ See the details at https://www.benpickles.com/articles/72-downgrading-kubectl-with-homebrew to downgrade with `homebrew`.

	+ specific version with `curl`

	For example, to download version v1.12.0 on macOS, type:

	```bash
	$ curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/darwin/amd64/kubectl
	$ chmod +x ./kubectl
	$ sudo mv ./kubectl /usr/local/bin/kubectl
	```

- Test `kubectl` version you installed:

	```bash
	$ kubectl version
	```

### Uninstall

- Uninstall with `Homebrew`, type:

	```bash
	$ brew uninstall kubernetes-cli
	```

	if you want to uninstall all version you have ever installed, type:

	```bash
	$ brew uninstall --force kubernetes-cli
	```

- Uninstall from `rm` command (if you install with `kubectl` binary using `curl` ), type:

	```bash
	$ rm -rf /usr/local/bin/kubectl # may be you need to run command with `sudo`
	```

### Enabling shell autocompletion

On macOS, you will need to install `bash-completion` support via Homebrew first:

```bash
## If running Bash 3.2 included with macOS
$ brew install bash-completion
## or, if running Bash 4.1+
$ brew install bash-completion@2
```

If you installed `kubectl` using the Homebrew instructions then `kubectl` completion should start working immediately.

> If bash-completion in Homebrew not work, please add to `~/.bash_profile`:

```bash
$ if [ -d $(brew --prefix)/etc/bash_completion.d ]; then
	. $(brew --prefix)/etc/bash_completion.d/kubectl
	fi
```

If you have installed `kubectl` manually, you need to add `kubectl` autocompletion to the bash-completion:

```bash
$ kubectl completion bash > $(brew --prefix)/etc/bash_completion.d/kubectl
```

## <a name="kubectl_linux"></a>Linux (Ubuntu)

### Install

- Latest version

	+ follow the official documentation at https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux.

- Downgrading or upgrading version:

	```bash
	$ snap remove kubectl #remove the installed version
	$ snap info kubectl   # check the list of kubectl versions
	$ sudo snap install --channel 1.11/stable --classic kubectl #install v1.11
	```

- Test `kubectl` version you installed:

	```bash
	$ kubectl version
	```

### Uninstall

Uninstall, please type:

```bash
$ sudo apt-get remove -y kubectl
```

### Enabling shell autocompletion

If bash-completion is not installed on Linux, please install the `bash-completion` package via your distribution's package manager.

Load the kubectl completion code for bash into the current shell

```bash
$ source <(kubectl completion bash)
```

Write bash completion code to a file and source if from `~/.bash_profile`:

```bash
$ kubectl completion bash > ~/.kube/completion.bash.inc
$ printf "source '$HOME/.kube/completion.bash.inc'" >> $HOME/.bash_profile
$ source $HOME/.bash_profile
```

## <a name="kubectl_windows"></a>Windows

Requirement: **Open `git-bash` with `Run as Administrator`**.

### Install

- Latest version:

	+ follow the official documentation at https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-windows.

- Downgrading or upgrading version:

	+ to upgrade

	```
	$ choco upgrade kubernetes-cli -y
	```

	+ to downgrade

	```
	$ choco install kubernetes-cli --version 1.11 -y --allow-downgrade
	```

- Test `kubectl` version you installed:

	```bash
	$ kubectl version
	```

### Uninstall

- Uninstall with `chocolatey`, type:

	```bash
	$ choco uninstall -y kubernetes-cli
	```

- Uninstall from `rm` command (if you install with kubectl binary using `curl` ), type:

	```bash
	$ rm -rf /usr/bin/kubectl
	```

### Enabling shell autocompletion

To add kubectl autocompletion to your current shell, run:

```bash
$ source <(kubectl completion bash).
```

To add kubectl autocompletion to your profile, so it is automatically loaded in future shells run:

```bash
echo "source <(kubectl completion bash)" >> ~/.bashrc # or ~/.bash_profile
```

Re-run your current shell with `Run As Administrator` to enable kubectl autocompletion.

> Note: **kubectl autocompletion will only work with `kubectl`, not `kubectl.exe`**.

# Helm
``helm`` is a package management tool for Kubernetes, and is used to deploy charts. In this section, you should know how to install helm.

## <a name="helm_mac_os"></a>Mac Os

### Install

- Latest version:

	+ If you are using [Homebrew](https://brew.sh/) package manager, you can install latest `helm` version with Homebrew.

	Run the installation command:

	```bash
	$ brew install kubernetes-helm
	$ brew link --overwrite kubernetes-helm # to ensure override new helm version to path
	```

- Specific version:

	+ If you have ever installed the desired version with `homebrew`, you can downgrade to that version.

	```bash
	$ brew info kubernetes-helm
	$ brew switch kubernetes-helm 2.11.0 # example downgrade to version 2.11.0
	```

	+ Install a specific version [from the binary release](https://docs.helm.sh/using_helm/#from-the-binary-releases)

- Test `kubectl` version you installed:

	```bash
	$ kubectl version
	```

### Uninstall

- Uninstall with `Homebrew`, type:

	```bash
	$ brew uninstall kubernetes-helm
	```

	if you want to uninstall all version you have ever installed, type:

	```bash
	$ brew uninstall --force kubernetes-helm
	```

- Uninstall from `rm` command, type:

	```bash
	$ rm -rf /usr/local/bin/helm # may be you need to run command with `sudo`
	```

### Enabling shell autocompletion

On macOS, you will need to install `bash-completion` support via Homebrew first:

```bash
## If running Bash 3.2 included with macOS
$ brew install bash-completion
## or, if running Bash 4.1+
$ brew install bash-completion@2
```

If you installed `helm` using the Homebrew instructions then `helm` completion should start working immediately.

> If bash-completion in Homebrew not work, please add to `~/.bash_profile`:

```bash
$ if [ -d $(brew --prefix)/etc/bash_completion.d ]; then
	. $(brew --prefix)/etc/bash_completion.d/helm
	fi
```

If you have installed `helm` manually, you need to add `helm` autocompletion to the bash-completion:

```bash
$ helm completion bash > $(brew --prefix)/etc/bash_completion.d/helm
```

## <a name="helm_linux"></a>Linux (Ubuntu)

### Install

- Latest version

	+ Install `helm` binary using `snap`.

	Run the installation command:

	```bash
	$ sudo snap install helm --classic
	```

- Specific version:

	+ Install a specific version:

	For example, to downgrade to version v2.11.0, type:

	```bash
	$ curl -Lo /tmp/helm-linux-amd64.tar.gz https://kubernetes-helm.storage.googleapis.com/helm-v2.11.0-linux-amd64.tar.gz
	$ tar -xvf /tmp/helm-linux-amd64.tar.gz -C /tmp/
	$ chmod +x /tmp/linux-amd64/helm && sudo mv /tmp/linux-amd64/helm /usr/local/bin/
	```

- Test `helm` version you installed:

	```bash
	$ helm version
	```

### Uninstall

- Uninstall with `snap`, please type:

	```bash
	$ sudo snap remove helm
	```

### Enabling shell autocompletion

If bash-completion is not installed on Linux, please install the `bash-completion` package via your distribution's package manager.

Load the kubectl completion code for bash into the current shell

```bash
$ source <(helm completion bash)
```

Write bash completion code to a file and source if from `~/.bash_profile`:

```bash
$ echo "source <(helm completion bash)" >> ~/.bash_profile
$ source ~/.bash_profile
```

## <a name="helm_windows"></a>Windows

Requirement: **Open `git-bash` with `Run as Administrator`**.

### Install

- Latest version:

	If you are using [Chocolatey](https://chocolatey.org/) package manager, you can install latest `helm` version with `chocolatey`.

	Run the installation command:

	```bash
	$ choco install -y kubernetes-helm
	```

- Specific version:

	+ Please check version you need in [Chocolatey Packages](https://chocolatey.org/packages/kubernetes-cli), then type:

	```bash
	$ choco install -y kubernetes-helm --version 2.11.0 --allow-downgrade # or --force
	```

- Test `helm` version you installed:

	```bash
	$ helm version
	```

### Uninstall

- Uninstall with `chocolatey`, type:

	```bash
	$ choco uninstall -y kubernetes-helm
	```

### Enabling shell autocompletion

To add `helm` autocompletion to your current shell, run:

```bash
$ source <(helm completion bash).
```

To add `helm` autocompletion to your profile, so it is automatically loaded in future shells run:

```bash
echo "source <(helm completion bash)" >> ~/.bashrc # or ~/.bash_profile
```

Re-run your current shell with `Run As Administrator` to enable `helm` autocompletion.

> Note: **helm autocompletion will only work with `helm`, not `helm.exe`**.
