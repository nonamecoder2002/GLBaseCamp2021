provider "aws" {
  region                  = "us-east-2"
  shared_credentials_file = "/home/alex/.aws/credentials"

}

# Cloud Network------------------
resource "aws_vpc" "noodle_vpc" {
  cidr_block = "10.10.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "My_VPC"
  }
}

resource "aws_subnet" "noodle_subnet_1" {
  vpc_id = aws_vpc.noodle_vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "My_Subnet_1"
  }
}

resource "aws_subnet" "noodle_subnet_2" {
  vpc_id = aws_vpc.noodle_vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "My_Subnet_2"
  }
}

resource "aws_internet_gateway" "noodle_gateway" {
  vpc_id = aws_vpc.noodle_vpc.id

  tags = {
    Name = "My Gateway"
  }
}

resource "aws_route_table" "noodle_table" {
  vpc_id = aws_vpc.noodle_vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id= aws_internet_gateway.noodle_gateway.id
  }
}

# FireWall----------------------------------
resource "aws_security_group" "allow_http" {
  name = "Allow Traffic"
  description = "Allow traffic"
  vpc_id = aws_vpc.noodle_vpc.id
  
  ingress {
    description      = "Allow HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    
  }
  
  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "My_Group"
  }
  
}

# VM--Instances----------------------------------------------
resource "aws_instance" "vm_1" {
  ami = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.noodle_subnet_1.id
  vpc_security_group_ids = [aws_security_group.allow_http.id ]
  associate_public_ip_address = true
  key_name = "ec2-key"

  tags = {
    Name = "VM_1"
  }

}

resource "aws_instance" "vm_2" {
  ami = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.noodle_subnet_2.id
  vpc_security_group_ids = [ aws_security_group.allow_http.id ]
  associate_public_ip_address = true
  key_name = "ec2-key"

  tags = {
    Name = "VM_2"
  }
}

# LOAD-BALANCER-----------------------------------
resource "aws_lb_target_group" "noodle_targets" {
  name = "my-target-group"
  port = 80
  protocol = "TCP"
  vpc_id = aws_vpc.noodle_vpc.id

}

resource "aws_lb_target_group_attachment" "noodle_tar_attach_1" {
  target_group_arn = aws_lb_target_group.noodle_targets.arn
  target_id = aws_instance.vm_1.id
  port = 80
}

resource "aws_lb_target_group_attachment" "noodle_tar_attach_2" {
  target_group_arn = aws_lb_target_group.noodle_targets.arn
  target_id = aws_instance.vm_2.id
  port = 80
}

resource "aws_lb" "noodle_balancer" {
name = "my-balancer"
internal = false
load_balancer_type = "network"
subnets = [ aws_subnet.noodle_subnet_1.id, aws_subnet.noodle_subnet_2.id ]
enable_deletion_protection = true
  
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.noodle_balancer.arn
  port = 80
  protocol = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.noodle_targets.arn
  }
  
}
