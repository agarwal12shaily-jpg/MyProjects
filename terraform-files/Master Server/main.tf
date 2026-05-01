# SERVER1: 'MASTER-SERVER' (with Jenkins, Maven, Docker, Ansible, Trivy)
# STEP1: CREATING A SECURITY GROUP FOR JENKINS SERVER
# Description: Allow SSH, HTTP, HTTPS, 8080, 8081
module "sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "my-security-group1"
  description = "Allow SSH, HTTP, HTTPS, 8080 for Jenkins & Maven"

  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Jenkins"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8081
      to_port     = 8081
      protocol    = "tcp"
      description = "SonarQube"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  tags = {
    name = "jenkins-sg"
  }
}

# EC2
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "main-ec2"

  instance_type               = "t3.small"
  key_name                    = "mykey"
  create_security_group       = false
  vpc_security_group_ids      = [module.sg.security_group_id]
  monitoring                  = true
  associate_public_ip_address = true
  user_data                   = file("installation.sh")
  ami = data.aws_ami.amazon_linux.id
  availability_zone           = data.aws_availability_zones.azs.names[0]

  tags = {
    name        = "Master-Server"
    Terraform   = "true"
    Environment = "dev"
  }
}


# STEP3: OUTPUT PUBLIC IP OF EC2 INSTANCE
output "MASTER_SERVER_PUBLIC_IP" {
  value = module.ec2_instance.public_ip
}

# STEP4: OUTPUT PRIVATE IP OF EC2 INSTANCE
output "MASTER_SERVER_PRIVATE_IP" {
  value = module.ec2_instance.private_ip
}

output "ACCESS_YOUR_JENKINS_HERE" {
  value = "http://${module.ec2_instance.public_ip}:8080"
}

output "Jenkins_Initial_Password" {
  value = "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
}

