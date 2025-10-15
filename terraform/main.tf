provider "aws" {
  region = "us-east-1"
}

variable "key_name" {
  description = "AWS Key Pair Name"
  type        = string
}

variable "ssh_ports" {
  type    = list(number)
  default = [22, 222, 2222, 2223, 2224, 2225]
}

# Fetch default VPC
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "ssh_sg" {
  name        = "ssh-sg"
  description = "Allow SSH ports"
  vpc_id      = data.aws_vpc.default.id

  # Open all SSH ports dynamically
  dynamic "ingress" {
    for_each = var.ssh_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 instance
resource "aws_instance" "devops_vm" {
  ami                    = "ami-0360c520857e3138f"  # Ubuntu 22.04
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]

  tags = { Name = "DevOps-VM" }
}

output "ec2_public_ip" {
  value = aws_instance.devops_vm.public_ip
}
