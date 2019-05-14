This page shows you how to install kubectl and helm on macOS, Linux (Ubuntu) and Windows. Also this guide instructs you the way to enable shell autocompletion.

This guide consists of two main sections:
- [Kubectl](#kubectl)
	+ [Installing / Uninstalling kubectl on macOS](#kubectl_mac_os)
	+ [Installing / Uninstalling kubectl on Linux(Ubuntu)](#kubectl_linux)
	+ [Installing / Uninstalling kubectl on Windows](#kubectl_windows)

- [Helm](#helm)
	+ [Installing / Uninstalling helm on macOS](#helm_mac_os)
	+ [Installing / Uninstalling helm on Linux(Ubuntu)](#helm_linux)
	+ [Installing / Uninstalling helm on Windows](#helm_windows)
	
# Requirements:
- Homebrew available on macOS
- Chocolatey available on Windows
- At least Ubuntu 16.04

# <a name="kubectl"></a>Kubectl
``kubectl`` is the Kubernetes command line tool, which can be used to deploy settings to the cluster.
In this section, you should know how to install kubectl.

## <a name="kubectl_mac_os"></a>Installing / Uninstalling kubectl on macOS

### Installing kubectl on macOS

- Install kubectl with `homebrew`:

	+ Follow the official documentation at https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-macos to install the latest version.

- Switch to a version which you already installed with `homebrew`

	```bash
	$ brew info kubernetes-cli
	$ brew switch kubernetes-cli 1.12.0 # example downgrade to version 1.12.0
	```
- Downgrade kubectl with `homebrew`: See the details at https://www.benpickles.com/articles/72-downgrading-kubectl-with-homebrew to downgrade with `homebrew`.

- Install a kubectl specific version with `curl`:

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

### Uninstalling kubectl on macOS

- Uninstall with `Homebrew`:

	```bash
	$ brew uninstall kubernetes-cli
	```

	If you want to uninstall all versions you have ever installed, run the command below:

	```bash
	$ brew uninstall --force kubernetes-cli
	```

- Uninstall with the `rm` command (if you installed `kubectl` with `curl` ):

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

If you installed `kubectl` using the Homebrew instructions, then `kubectl` completion should start working immediately.

If bash-completion in Homebrew does not work, please add to `~/.bash_profile`:

```bash
$ if [ -d $(brew --prefix)/etc/bash_completion.d ]; then
	. $(brew --prefix)/etc/bash_completion.d/kubectl
	fi
```

If you have installed `kubectl` manually, you need to add `kubectl` autocompletion to the bash-completion:

```bash
$ kubectl completion bash > $(brew --prefix)/etc/bash_completion.d/kubectl
```

## <a name="kubectl_linux"></a>Installing / Uninstalling kubectl on Linux (Ubuntu)

### Installing kubectl on Linux

- Install the latest version:

	+ Follow the official documentation at https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux.

- Install a specific version:

	```bash
	$ snap remove kubectl #remove the installed version
	$ snap info kubectl   # check the list of kubectl versions
	$ sudo snap install --channel 1.11/stable --classic kubectl #install v1.11
	```

- Test `kubectl` version you installed:

	```bash
	$ kubectl version
	```

### Uninstalling kubectl on Linux

To uninstall the kubectl on Linux, type the command:

```bash
$ sudo apt-get remove -y kubectl
```

### Enabling shell autocompletion

If bash-completion is not installed on Linux yet, please install the `bash-completion` package via your distribution's package manager.

- Load the kubectl completion code for bash into the current shell:

```bash
$ source <(kubectl completion bash)
```

- Write the bash completion code to a file and source it from `~/.bash_profile`:

```bash
$ kubectl completion bash > ~/.kube/completion.bash.inc
$ printf "source '$HOME/.kube/completion.bash.inc'" >> $HOME/.bash_profile
$ source $HOME/.bash_profile
```

## <a name="kubectl_windows"></a>Installing / Unistalling kubectl on Windows

Requirement: **Open `git-bash` with `Run as Administrator`**.

### Installing kubectl on Windows

- Install the latest version:

	+ Follow the official documentation at https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-windows.

- Upgrade kubectl to the newer version:

	```
	$ choco upgrade kubernetes-cli -y
	```
- Downgrade into an older version, for example, version 1.11:

	```
	$ choco install kubernetes-cli --version 1.11 -y --allow-downgrade
	```

- Test `kubectl` version you installed:

	```bash
	$ kubectl version
	```

### Uninstall kubectl on Windows

- Uninstall with `chocolatey`, type:

	```bash
	$ choco uninstall -y kubernetes-cli
	```

- Uninstall with `rm` command (if you installed kubectl with `curl` ), type:

	```bash
	$ rm -rf /usr/bin/kubectl
	```

### Enabling shell autocompletion

To add kubectl autocompletion to your current shell, run the command:

```bash
$ source <(kubectl completion bash).
```

To add kubectl autocompletion to your profile so it is automatically loaded in future shells, run the command:

```bash
echo "source <(kubectl completion bash)" >> ~/.bashrc # or ~/.bash_profile
```

Re-run your current shell with `Run As Administrator` to enable kubectl autocompletion.

> Note: **kubectl autocompletion will only work with `kubectl`, not `kubectl.exe`**.

# <a name="helm">Helm
``helm`` is a package management tool for Kubernetes, and is used to deploy charts. In this section, you should know how to install helm.

## <a name="helm_mac_os"></a>Installing / Uninstall helm on macOS

### Installing helm on macOS

- Install the latest version with `[homebrew]`(https://brew.sh/):

	```bash
	$ brew install kubernetes-helm
	$ brew link --overwrite kubernetes-helm # to ensure override new helm version to path
	```

- Switch to any version which you have already installed with `homebrew`:
	
	```bash
	$ brew info kubernetes-helm
	$ brew switch kubernetes-helm 2.11.0 # example downgrade to version 2.11.0
	```
	
- Or install a specific version with `homebrew` by following the steps below, to have more details, see https://github.com/helm/helm/issues/4547#issuecomment-423312200.

 	+ Click https://github.com/Homebrew/homebrew-core/search?q=kubernetes-helm&type=Commits to search for the correct `kubernetes-helm.rb` file for the version, for example, v2.9.1.
	+ Click the commit hash button (78d6425)
	+ Click the "View" button
	+ Click the "Raw" button
	+ Copy the url: https://raw.githubusercontent.com/Homebrew/homebrew-core/78d64252f30a12b6f4b3ce29686ab5e262eea812/Formula/kubernetes-helm.rb
	+ Run the commands below:

	```
	$ brew unlink kubernetes-helm
	$ brew install https://raw.githubusercontent.com/Homebrew/homebrew-	core/78d64252f30a12b6f4b3ce29686ab5e262eea812/Formula/kubernetes-helm.rb
	$ brew switch kubernetes-helm 2.9.1
	```

- Install a specific version [from the binary release](https://docs.helm.sh/using_helm/#from-the-binary-releases).

- Test `helm` version you installed:

	```bash
	$ helm version
	```

### Uninstalling helm on macOS

- Uninstall helm with `Homebrew`, type the command:

	```bash
	$ brew uninstall kubernetes-helm
	```

	If you want to uninstall all versions you have ever installed, type the command:

	```bash
	$ brew uninstall --force kubernetes-helm
	```

- Uninstall helm with the `rm` command, type the command:

	```bash
	$ rm -rf /usr/local/bin/helm # may be you need to run command with `sudo`
	```

### Enabling shell autocompletion

On macOS, you will need to install `bash-completion` support via `Homebrew` first:

```bash
## If running Bash 3.2 included with macOS
$ brew install bash-completion
## or, if running Bash 4.1+
$ brew install bash-completion@2
```

If you installed `helm` using the Homebrew instructions, then `helm` completion should work immediately.

If bash-completion in Homebrew does not work, please add to `~/.bash_profile`:

```bash
$ if [ -d $(brew --prefix)/etc/bash_completion.d ]; then
	. $(brew --prefix)/etc/bash_completion.d/helm
	fi
```

If you have installed `helm` manually, you need to add `helm` autocompletion to the bash-completion:

```bash
$ helm completion bash > $(brew --prefix)/etc/bash_completion.d/helm
```

## <a name="helm_linux"></a>Installing / Uninstalling helm on Linux (Ubuntu)

### Installing helm on Linux

- Install the latest version with `snap`:

	```bash
	$ sudo snap install helm --classic
	```

- Install a specific version, for example, you want to install an older version v2.11.0:

	```bash
	$ curl -Lo /tmp/helm-linux-amd64.tar.gz https://kubernetes-helm.storage.googleapis.com/helm-v2.11.0-linux-amd64.tar.gz
	$ tar -xvf /tmp/helm-linux-amd64.tar.gz -C /tmp/
	$ chmod +x /tmp/linux-amd64/helm && sudo mv /tmp/linux-amd64/helm /usr/local/bin/
	```

- Test `helm` version you installed:

	```bash
	$ helm version
	```

### Uninstallong helm on Linux

- Uninstall with `snap`, please type:

	```bash
	$ sudo snap remove helm
	```

### Enabling shell autocompletion

If bash-completion is not installed on Linux, please install the `bash-completion` package via your distribution's package manager.

- Load the kubectl completion code for bash into the current shell:

```bash
$ source <(helm completion bash)
```

- Write bash completion code to a file and source if from `~/.bash_profile`:

```bash
$ echo "source <(helm completion bash)" >> ~/.bash_profile
$ source ~/.bash_profile
```

## <a name="helm_windows"></a>Installing / Uninstalling helm on Windows

Requirement: **Open `git-bash` with `Run as Administrator`**.

### Installing helm on Windows:

- Install the latest version with [Chocolatey](https://chocolatey.org/):

	```bash
	$ choco install -y kubernetes-helm
	```

- Install a specific version, for example, version 2.11.0:

	+ Please check version you need in [Chocolatey Packages](https://chocolatey.org/packages/kubernetes-cli), then type:

	```bash
	$ choco install -y kubernetes-helm --version 2.11.0 --allow-downgrade # or --force
	```

- Test `helm` version you installed:

	```bash
	$ helm version
	```

### Uninstalling helm on Windows:

- Uninstall with `chocolatey`, type:

	```bash
	$ choco uninstall -y kubernetes-helm
	```

### Enabling shell autocompletion

To add `helm` autocompletion to your current shell, run the command:

```bash
$ source <(helm completion bash).
```

To add `helm` autocompletion to your profile so it is automatically loaded in future shells, run the command:

```bash
echo "source <(helm completion bash)" >> ~/.bashrc # or ~/.bash_profile
```

Re-run your current shell with `Run As Administrator` to enable `helm` autocompletion.

> Note: **helm autocompletion will only work with `helm`, not `helm.exe`**.
