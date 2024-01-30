#! /usr/bin/bash

echo "Disabling interactive mode for sysctl"
sudo sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

echo "Update Ubuntu packages"
sudo apt -y update && sudo apt -y upgrade

echo "Change hostname to control-plane"
sudo hostnamectl set-hostname control-plane

echo "Add hostname to hosts file"
ip_address=$(    | awk '/inet/ {print $2}' | cut -d/ -f1)
hostname=$(hostname)
echo "$ip_address $hostname" | sudo tee -a /etc/hosts

echo "Disable memory swap - Ubuntu 22.04"
sudo sed -i '/swap/ s/^\(.*\)$/# \1/g' /etc/fstab
sudo swapoff -a

echo "Add Kernel parameters for Containerd"
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

echo "Add Kernel parameters for Kubernetes"
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

echo "Reload new kernel variables"
sudo sysctl --system

echo "Install containerd support packages"
sudo apt install -y gnupg2

echo "Containerd setup"
# Add Docker's official GPG key:
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

#Remove any previous packages of docker or containerd installed
echo "Remove incompatible packages with containerd"
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; 
        do sudo apt-get -y remove $pkg;
    done

#install containerd from docker repository
sudo apt-get install -y containerd.io

#Configure containerd for systemd usage
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

#Restart and enable containerd for the new configuration
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "Download and configure gpg key for Kubernetes"
sudo mkdir -p /etc/apt/keyrings
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "Install kubelet, kubeadm and kubectl"
sudo apt update -y
sudo apt -y install kubelet=1.29.0-1.1 kubeadm=1.29.0-1.1 kubectl=1.29.0-1.1

echo "Hold kubelet, kubeadm and kubectl versions"
sudo apt-mark hold kubelet kubeadm kubectl

echo "image pull and cluster setup"
sudo kubeadm config images pull --kubernetes-version v1.29.0
sudo kubeadm init   --pod-network-cidr=10.244.0.0/16   --upload-certs --kubernetes-version=v1.29.0  --control-plane-endpoint=$(hostname) --cri-socket unix:///var/run/containerd/containerd.sock

echo "Apply flannel network"
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
sudo systemctl restart kubelet

#Add kubectl to your local environment
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "Enabling interactive mode for sysctl"
sudo sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf