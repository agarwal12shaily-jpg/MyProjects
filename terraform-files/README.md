The above Terraform files will create 'Jenkins' & 'K8s' servers
Master-Server --> Git, Maven, Docker, Trivy, Ansible
Node-Server --> Docker, K8s (Kubeadm)
NOTE:
Create a 'My_key.pem' from AWS EC2 console
Save the key file in the same location as your terraform code