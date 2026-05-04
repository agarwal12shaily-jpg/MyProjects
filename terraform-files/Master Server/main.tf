# Security Group
module "sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "jenkins-devops-sg"
  description = "Allow SSH, Jenkins, HTTP, HTTPS, SonarQube"

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Jenkins"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8081
      to_port     = 8081
      protocol    = "tcp"
      description = "SonarQube"
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
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS"
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
}

# EC2
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-master"

  instance_type               = "t3.small"
  key_name                    = "mykey"
  ami                         = data.aws_ami.amazon_linux.id
  availability_zone           = data.aws_availability_zones.azs.names[0]
  associate_public_ip_address = true

  create_security_group  = false
  vpc_security_group_ids = [module.sg.security_group_id]

  user_data = file("installation.sh")

  root_block_device = {
      volume_size = 30
      volume_type = "gp3"
    }


  tags = {
    Name        = "Jenkins-Master"
    Environment = "Dev"
    Terraform   = "true"
  }
}

output "SERVER_PUBLIC_IP" {
  value = module.ec2_instance.public_ip
}

output "JENKINS_URL" {
  value = "http://${module.ec2_instance.public_ip}:8080"
}

output "SSH_COMMAND" {
  value = "ssh -i mykey.pem ec2-user@${module.ec2_instance.public_ip}"
}