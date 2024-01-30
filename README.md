# k8s-install-script

This is a basic script to setup a one-node Kubernetes solution on an Ubuntu 22.04 VM running in UTM on a Mac with Apple Silicon M1.

The script was adapted from one created by Saiyam Pathak and can be found here: https://gist.github.com/saiyam1814/d87598cf55c71953e288cd22858c0593 

# Some Information

The script does the main setup for a one-node Kubernetes service on an Ubuntu 22.04 VM ([Ubuntu 22.04.3 Live Server for ARM64](https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso)). Created specifically for use with a MacBook running Apple M1 Silicon, it might require adaptations for other architectures.

It uses Kubernetes version 1.29.0-1.1 (as of 01/30/2024). The goal is to explain each part of the script for those new to Kubernetes (k8s) or Linux. Any inconsistencies can be reported for corrections.

Clone this script in the HOME directory of the user created on Ubuntu. Make it executable with `sudo chmod +x <filename.sh>`. Run it with `./<filename.sh>`. As it requires sudo rights, your password will be prompted at the beginning.

# The Script

## Bash Executable
The first line specifies the bash executable location, which can vary depending on the Linux flavor. Use `which bash` in the CLI to find the current path. In this case, it's `/usr/bin/bash`.

## Disable Interactive Mode
Disabling interactive mode is necessary for unattended command execution, particularly after restarting `sysctl`. In Ubuntu, this setting is in `/etc/needrestart/needrestart.conf`. The `nrconf` value changes from 'i' to 'a'. More details are in the [Ubuntu manpages](https://manpages.ubuntu.com/manpages/jammy/man1/needrestart.1.html).

## Update Ubuntu
This step updates Ubuntu packages to their latest versions, which is a recommended practice for bug fixes and security patches. The `-y` option allows unattended operation.

## Change Hostname
Changing the hostname to `control-plane` aligns with Kubernetes documentation. This step is optional and can be skipped by commenting out the lines.

## Local Hosts File
For small setups, it's good practice to add node names and IPs to the hosts file for DNS independence. This script parses the output of `ip -4 addr show scope global` with `awk` and `cut` to extract the IP address for the hosts file.

## Disable Swap
Following Kubernetes documentation, this part disables swap and comments it out in `/etc/fstab`. Swap must be off for Kubernetes installation, but implementation may vary across Linux distributions.

## Kernel Parameters for Container Runtime
These parameters, as per the [Kubernetes documentation](https://kubernetes.io/docs/setup/production-environment/container-runtimes/), enable the Linux kernel to handle routing and bridging for nodes and pods.

## Additional Kernel Parameters
Similar to the above, these settings ensure proper routing of IPv4 and IPv6 packets to iptables for network policies, and enable IP packet routing within Linux.

## Reload Kernel Parameters
This step applies the new kernel settings.

## Install Kubernetes Dependencies
Installs `gnupg2`, used for importing GPG keys for Kubernetes repositories.

## Containerd Setup
Since Kubernetes version 1.20, `containerd` is the default container runtime, following Docker's deprecation. This section sets up `containerd`.

- **Docker GPG Key and Repository**: Adds the Docker GPG key and repository for `containerd` installation.
- **Remove Conflicting Packages**: Removes packages that might conflict with `containerd`.
- **Install containerd.io**: Installs `containerd` from Docker's repository.
- **Configure containerd for systemd**: Configures `containerd` to use `systemd` as the cgroup manager, essential for Kubernetes.

## Kubernetes GPG Key and Repository
Sets up the official Kubernetes repository by adding its GPG key and the repository to the system.

## Install Kubernetes Components
Installs specific versions of `kubelet`, `kubeadm`, and `kubectl`, and holds their versions to prevent automatic updates.

## Initialize Kubernetes Cluster
- **Pre-pull Kubernetes Images**: Ensures all required images are available locally.
- **Initialize Cluster**: Initializes the Kubernetes cluster with `kubeadm init`, specifying the pod network CIDR and control plane endpoint.

## Apply Flannel CNI
Deploys the Flannel CNI configuration for pod networking.

## Configure kubectl for Local Administration
Sets up local `kubectl` configuration for cluster management.

## Taint Control Plane Node
Removes the `NoSchedule` taint from the control-plane node to allow pod scheduling on a single-node cluster.

## Re-Enable Interactive Mode
Reverts the `sysctl` interactive mode setting for user prompts.

This README provides an overview of each script step for installing and configuring a Kubernetes cluster on a single node. It automates various tasks to ensure a correctly configured Kubernetes environment.


## Things to do after the script is complete

Make sure to add kubectl to your bash environment:

- mkdir -p $HOME/.kube
- sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
- sudo chown $(id -u):$(id -g) $HOME/.kube/config

And enable autocomplition:

- sudo apt install bash-completion
- kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

Have fun!!! 