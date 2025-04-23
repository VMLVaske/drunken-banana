provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "deployer_new" {
  key_name   = "ghost-key-new"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "ghost_sg_new" {
  name        = "ghost_sg_new"
  description = "Allow SSH and HTTP access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "main_new" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ghost-vpc-new"
  }
}

resource "aws_subnet" "public_new" {
  vpc_id            = aws_vpc.main_new.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ghost-subnet-new"
  }
}

resource "aws_instance" "ghost_ec2_new" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer_new.key_name
  vpc_security_group_ids      = [aws_security_group.ghost_sg_new.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/userdata.sh", {
    backup_email = var.backup_email
    deployer_public_key  = var.deployer_public_key
  })

  tags = {
    Name = "GhostBlogInstance_new"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_eip" "ghost_eip_new" {
  vpc = true
  depends_on = [aws_instance.ghost_ec2_new]
}

resource "aws_eip_association" "eip_assoc_new" {
  instance_id   = aws_instance.ghost_ec2_new.id
  allocation_id = aws_eip.ghost_eip_new.id
}