# SERVER2: 'NODE-SERVER' (with Docker & Kubernetes)
# STEP1: CREATING A SECURITY GROUP FOR DOCKER-K8S
# Description: K8s requires ports 22, 80, 443, 6443, 8001, 10250, 30000-32767
module "sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "node-security-group"
  description = "Allow K8s ports"

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
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
    },

    {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      description = "Kubernetes API"
      cidr_blocks = "0.0.0.0/0"
    },

    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      description = "Kubelet"
      cidr_blocks = "0.0.0.0/0"
    },

    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      description = "NodePort"
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
    name = "node-security-group"
  }
}

# EC2
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "Node-ec2"

  instance_type               = "c7i-flex.large"
  key_name                    = "mykey"
  create_security_group       = false
  vpc_security_group_ids      = [module.sg.security_group_id]
  monitoring                  = true
  associate_public_ip_address = true
  user_data                   = file("installation1.sh")
  ami                         = data.aws_ami.amazon_linux.id
  availability_zone           = data.aws_availability_zones.azs.names[0]

  root_block_device = {
    volume_size = 30
  }

  tags = {
    name        = "Node-Server"
    Terraform   = "true"
    Environment = "dev"
  }
}


# STEP3: OUTPUT PUBLIC IP OF EC2 INSTANCE
output "NODE_SERVER_PUBLIC_IP" {
  value = module.ec2_instance.public_ip
}

# STEP4: OUTPUT PRIVATE IP OF EC2 INSTANCE
output "NODE_SERVER_PRIVATE_IP" {
  value = module.ec2_instance.private_ip
}
