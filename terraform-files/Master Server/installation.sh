#!/bin/bash
set -euxo pipefail

exec > /var/log/user-data.log 2>&1

echo "===== STARTING SETUP ====="

sleep 30

########################################
# UPDATE SYSTEM
########################################
dnf update -y

########################################
# BASE PACKAGES (FIXED: removed curl)
########################################
dnf install -y git wget unzip tar zip which nano python3

########################################
# JAVA
########################################
dnf install -y java-21-amazon-corretto
java -version

JAVA_HOME_PATH=$(readlink -f $(which java) | sed "s:/bin/java::")
echo "Detected JAVA_HOME: $JAVA_HOME_PATH"

########################################
# CONFIGURE JAVA FOR JENKINS
########################################
mkdir -p /etc/systemd/system/jenkins.service.d

cat <<EOF > /etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JAVA_HOME=$JAVA_HOME_PATH"
Environment="PATH=$JAVA_HOME_PATH/bin:/usr/bin:/bin"
EOF

########################################
# MAVEN
########################################
dnf install -y maven
mvn -version

########################################
# DOCKER
########################################
dnf install -y docker

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

docker --version

########################################
# JENKINS
########################################
wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

dnf install -y jenkins

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable jenkins

sleep 30
systemctl start jenkins

########################################
# TERRAFORM
########################################
dnf install -y dnf-plugins-core

dnf config-manager --add-repo \
https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

dnf install -y terraform
terraform version

########################################
# TRIVY
########################################
cat <<EOF > /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/
gpgcheck=0
enabled=1
EOF

dnf install -y trivy

########################################
# ANSIBLE
########################################
dnf install -y ansible



########################################
# KUBECTL
########################################
#curl -LO https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl

#chmod +x kubectl
#mv kubectl /usr/local/bin/

#kubectl version --client

########################################
# MINIKUBE (OPTIONAL BUT IMPORTANT)
########################################
#curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

#install minikube-linux-amd64 /usr/local/bin/minikube

########################################
# RESTART SERVICES
########################################
systemctl restart docker
systemctl restart jenkins

#########################################
# FINAL CHECK
########################################
sleep 30

echo "===== VALIDATION ====="
java -version
docker --version
mvn -version
terraform version
ansible --version

echo "===== JENKINS STATUS ====="
systemctl status jenkins --no-pager || true

echo "===== JENKINS PASSWORD ====="
cat /var/lib/jenkins/secrets/initialAdminPassword || echo "Jenkins not ready yet"

echo "===== DONE ====="



#sudo tail -f /var/log/user-data.log