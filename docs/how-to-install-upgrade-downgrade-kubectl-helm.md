This page shows you how to install, upgrade and downgrade kubectl and helm on macOS, Linux (Ubuntu) and Windows via the packages:

- Homebrew on macOS
- Snap on Linux (Ubuntu)
- Chocolatey on Windows

# Requirements:

- homebrew available on macOS
- chocolatey available on Windows
- Ubuntu is preferred Linux distro


# Installing, upgrading and downgrading kubectl on your computer
``kubectl`` is the Kubernetes command line tool, which can be used to deploy settings to the cluster.
In this section, you should know how to install, upgrade and downgrade a version of kubectl. 

## Installing kubectl

With the guide below, the latest version of kubeclt should be installed.



- On macOS, follow the official documentation at https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-homebrew-on-macos.

- On Linux (Ubuntu), follow the official documentation at https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-snap-on-ubuntu.

- On Windows, follow the official documentation at https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-chocolatey-on-windows.

Note: On Windows, to install kubectl with the autocompletion, you should add the option `-y` at the end of the command.

```
choco install kubernetes-cli -y
```

## Upgrading kubectl
This section shows you how to upgrade the latest verion of kubeclt.

- On macOs:

```
brew upgrade kubernetes-cli
```

- On Linux (Ubuntu):

//TODO

- On Window, use the command:

```
choco upgrade kubernetes-cli -y
```


## Downgrading kubectl 

This section shows you how to install an older version of kubectl, e.g `verion 1.11`, use the command below:

- On macOs: See the details at https://www.benpickles.com/articles/72-downgrading-kubectl-with-homebrew

- On Linux (Ubuntu):

//TODO

- On Windows:

```
$ choco install kubernetes-cli --version 1.11 -y --allow-downgrade
```

# Installing, upgrading and downgrading helm on your computer

Helm is a package management tool for Kubernetes, and is used to deploy charts. In this section, you should know how to install, upgrade and downgrade helm.

## Installing helm

To install the latest version of helm on different OS, please see this official document https://docs.helm.sh/using_helm/#installing-the-helm-client.

Note: To install helm with the autocompletion, you should add the option `-y` at the end of the command.
For example, install the helm on Windows:

```
choco install kubernetes-helm -y
```
## Upgrading helm

- On macOs:

```
brew upgrade kubernetes-helm
```

- On Linux (Ubuntu):

//TODO

- On Windows:

```
choco upgrade kubernetes-helm -y
```


## Downgrading helm
You can install an older verion of helm, e.g `verion 2.10.0`, use the command below:

- On macOs: 

You can switch to an installed verion, for example, version 2.9.1

```
$ brew switch kubernetes-helm 2.9.1```
```

Or install a specific version by following the steps below, to have more details, see https://github.com/helm/helm/issues/4547#issuecomment-423312200.
	- Click https://github.com/Homebrew/homebrew-core/search?q=kubernetes-helm&type=Commits to search for the correct `kubernetes-helm.rb` file for the version, for example, v2.9.1.
	- Click the commit hash button (78d6425)
	- Click the "View" button
	- Click the "Raw" button
	- Copy the url: https://raw.githubusercontent.com/Homebrew/homebrew-core/78d64252f30a12b6f4b3ce29686ab5e262eea812/Formula/kubernetes-helm.rb
	- Run the commands below:

	```
	$ brew unlink kubernetes-helm
	$ brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/78d64252f30a12b6f4b3ce29686ab5e262eea812/Formula/kubernetes-helm.rb
	$ brew switch kubernetes-helm 2.9.1
	```

- On Linux (Ubuntu):

//TODO

- On Windows:

```
$ choco install kubernetes-helm --version 2.10.0 -y --allow-downgrade
```