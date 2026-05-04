#!/bin/bash
set -x

exec > /var/log/user-data.log 2>&1

# Wait for boot completion
sleep 40

dnf update -y

# Base packages
dnf install -y \
git \
wget \
curl \
unzip \
tar \
zip \
which \
nano \
python3 \
amazon-ec2-instance-connect \
java-21-amazon-corretto \
maven \
docker

# Enable services
systemctl enable docker
systemctl start docker

systemctl enable sshd
systemctl restart sshd

# Users to docker group
usermod -aG docker ec2-user

# Jenkins Repo
wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Jenkins install
dnf install -y jenkins

systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

usermod -aG docker jenkins

# Terraform
dnf config-manager --add-repo \
https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

dnf install -y terraform

# Trivy
cat <<EOF > /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy Repo
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/
enabled=1
gpgcheck=0
EOF

dnf install -y trivy

# Ansible
dnf install -y ansible

# kubectl
curl -LO https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/

# Restart services
systemctl restart docker
systemctl restart jenkins

# Versions
java -version
terraform version
docker --version
mvn -version
kubectl version --client
trivy --version
ansible --version

# Jenkins password
cat /var/lib/jenkins/secrets/initialAdminPassword