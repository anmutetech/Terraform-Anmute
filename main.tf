terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create a VPC
resource "aws_vpc" "app_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "app-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "vpc_igw"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_rt_asso" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

##Create Key Pair
resource "tls_private_key" "key_type" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.instance_key
  public_key = tls_private_key.key_type.public_key_openssh
}

resource "local_file" "private_key" {
  depends_on = [
    aws_key_pair.generated_key
    ]
  content  = tls_private_key.key_type.private_key_pem
  filename = "anmute-devops.pem"
  file_permission = 0400
}

resource "local_file" "public_key" {
  depends_on = [
    aws_key_pair.generated_key
    ]
  content  = tls_private_key.key_type.public_key_pem
  filename = "anmute-devops-public.pem"
  file_permission = 0400
}
##Create EC2 Instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id 
  instance_type = var.instance_type
  key_name = var.instance_key
  subnet_id              = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.sg.id]
  
  tags = {
    Name = "web_instance"
  }

  volume_tags = {
    Name = "web_instance"
  } 
  
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install software-properties-common",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible -y",
      "sleep 30",
      "sudo apt install telnet",
      "echo 'Ready to proceed with ansible installations'",
	]

   connection {
   host     = self.public_ip
   type     = "ssh"
   user     = "ubuntu"
   private_key = tls_private_key.key_type.private_key_pem
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook  -i ${aws_instance.web.public_ip}, --private-key ${local_file.private_key.filename} nginx.yaml"
  }

}
