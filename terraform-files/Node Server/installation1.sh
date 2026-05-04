#!/bin/bash
set -euxo pipefail

exec > /var/log/user-data.log 2>&1

echo "Starting Kubernetes Master Node Setup..."

#################################################
# SYSTEM UPDATE
#################################################
dnf update -y

#################################################
# DISABLE SWAP
#################################################
swapoff -a
sed -i '/swap/d' /etc/fstab

#################################################
# LOAD KERNEL MODULES
#################################################
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

#################################################
# SYSCTL SETTINGS
#################################################
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

#################################################
# INSTALL CONTAINERD
#################################################
dnf install -y containerd

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

systemctl enable containerd
systemctl restart containerd

#################################################
# KUBERNETES REPOSITORY
#################################################
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl
EOF

#################################################
# INSTALL KUBERNETES TOOLS
#################################################
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable kubelet
systemctl start kubelet

#################################################
# INITIALIZE CLUSTER
#################################################
kubeadm init --pod-network-cidr=10.244.0.0/16

#################################################
# CONFIGURE KUBECTL FOR EC2-USER
#################################################
mkdir -p /home/ec2-user/.kube
cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
chown -R ec2-user:ec2-user /home/ec2-user/.kube

#################################################
# INSTALL FLANNEL CNI
#################################################
su - ec2-user -c "kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml"

#################################################
# SAVE JOIN COMMAND
#################################################
kubeadm token create --print-join-command > /home/ec2-user/join-node.sh

chown ec2-user:ec2-user /home/ec2-user/join-node.sh
chmod +x /home/ec2-user/join-node.sh

echo "Kubernetes Master Node Setup Completed"


# Check full installation status

# System services
sudo systemctl status containerd
sudo systemctl status kubelet

# Kubernetes tools
kubeadm version
kubectl version --client
kubelet --version

# Check cluster initialized or not
kubectl get nodes

# Check all pods
kubectl get pods -A

# Check flannel installed or not
kubectl get pods -n kube-flannel

# Check join command file exists or not
ls -l /home/ec2-user/join-node.sh

# Check user-data execution logs
sudo tail -100 /var/log/user-data.log