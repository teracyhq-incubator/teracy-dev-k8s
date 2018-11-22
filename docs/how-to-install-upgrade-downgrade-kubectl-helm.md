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
$ choco install kubernetes-cli -y
```

- To check the installed kubectl version, just run the command:

```
$ kubectl version

```

## Upgrading kubectl
This section shows you how to upgrade the latest verion of kubeclt.

- On macOs:

```
$ brew upgrade kubernetes-cli
```

- On Linux (Ubuntu): 

```
$ snap remove kubectl
$ sudo snap install kubectl --classic
```

- On Window, use the command:

```
$ choco upgrade kubernetes-cli -y
```


## Downgrading kubectl 

This section shows you how to install an older version of kubectl, e.g `verion 1.11`.

- On macOs: See the details at https://www.benpickles.com/articles/72-downgrading-kubectl-with-homebrew

- On Linux (Ubuntu):

```
$ snap remove kubectl #remove the installed version
$ snap info kubectl   # check the list of kubectl versions
$ sudo snap install --channel 1.11/stable --classic kubectl #install v1.11
```

- On Windows:

```
$ choco install kubernetes-cli --version 1.11 -y --allow-downgrade
```

# Installing, upgrading and downgrading helm on your computer

Helm is a package management tool for Kubernetes, and is used to deploy charts. In this section, you should know how to install, upgrade and downgrade helm.

## Installing helm

The commands below help you install the latest verion of hellm on different OS.

- On macOs:

```
$ brew install kubernetes-helm
```

- On Linux: Please see the details at https://docs.helm.sh/using_helm/#from-script

- On Windows:

```
$ choco install kubernetes-helm -y
```

To check the installed helm version, just run the command:

```
$ helm version

```


## Upgrading helm

- On macOs:

```
$ brew upgrade kubernetes-helm
```

- On Linux (Ubuntu): See the details at https://docs.helm.sh/using_helm/#from-script

- On Windows:

```
$ choco upgrade kubernetes-helm -y
```


## Downgrading helm
You can install an older verion of helm.

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

- On Linux (Ubuntu): To downgrade into the varion 2.10.0 for example:

```
$ curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash -s -- -v v2.10.0
```

- On Windows: To downgrade into the varion 2.10.0 for example:

```
$ choco install kubernetes-helm --version 2.10.0 -y --allow-downgrade
```