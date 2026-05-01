#!/bin/bash
set -euxo pipefail

# Update system
yum update -y

# Install base tools
yum install -y wget git unzip tar yum-utils fontconfig

# Install Java (recommended on AWS)
yum install -y java-21-amazon-corretto

# Verify Java
java -version

# Add Jenkins repo
wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/rpm-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
yum install -y jenkins

# Ensure JAVA_HOME for Jenkins
mkdir -p /etc/systemd/system/jenkins.service.d

cat > /etc/systemd/system/jenkins.service.d/override.conf <<EOF
[Service]
Environment="JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto"
EOF

# Reload systemd and start Jenkins
systemctl daemon-reload
systemctl enable jenkins
systemctl restart jenkins

# Install Git
sudo yum install git -y

# Install Terraform
yum install -y yum-utils
yum-config-manager --add-repo \
https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

yum install -y terraform

# Install Maven
yum install -y maven

# Install Docker
yum install -y docker
systemctl enable docker
systemctl start docker
# Add ec2-user to docker group
usermod -aG docker ec2-user

# Add Jenkins user to Docker group
usermod -aG docker jenkins

# Restart docker and Jenkins
systemctl restart docker
systemctl restart jenkins

yum install -y trivy

# Install Ansible
yum install -y ansible

# Show versions
terraform version
java version
mvn version
docker version
systemctl status jenkins --no-pager
trivy version
ansible version

# Install kubectl
curl -LO https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/







#set -e

# Log user-data output
#exec > /var/log/user-data.log 2>&1

#echo "Starting server configuration..."

# Wait for network / cloud-init completion
#sleep 30

# Update packages
#dnf update -y

# Install base tools
#dnf install -y git wget curl unzip tar

# Install Java 17
#dnf install -y java-17-amazon-corretto

# Install Maven
#dnf install -y maven

# Install Docker
#dnf install -y docker
#systemctl enable docker
#systemctl start docker

# Add ec2-user to docker group
#usermod -aG docker ec2-user

# Jenkins repo
#wget -O /etc/yum.repos.d/jenkins.repo \
#https://pkg.jenkins.io/redhat-stable/jenkins.repo

#rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
#dnf install -y jenkins
#systemctl enable jenkins
#systemctl start jenkins

# Add Jenkins user to Docker group
#usermod -aG docker jenkins

# Restart docker and Jenkins
#systemctl restart docker
#systemctl restart jenkins

# Install Trivy (latest repo method)
#cat <<EOF > /etc/yum.repos.d/trivy.repo
#[trivy]
#name=Trivy repository
#baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/
#gpgcheck=0
#enabled=1
#EOF

#dnf install -y trivy

# Install Ansible
#dnf install -y ansible

# Show versions
#java -version
#mvn -version
#docker --version
#jenkins --version || true
#trivy --version
#ansible --version

#echo "Installation completed successfully."