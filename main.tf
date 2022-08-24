provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "app_vpc"
  }
}

resource "aws_subnet" "app_subnet" {
  tags = {
    "Name" = "app_subnet"
  }
  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = "10.0.0.0/24"
  depends_on = [
    aws_vpc.app_vpc
  ]
}

resource "aws_route_table" "app_route_table" {
  tags = {
    "Name" = "app_route_table"
  }
  vpc_id = aws_vpc.app_vpc.id
}

resource "aws_route_table_association" "app_route_table_association" {
  subnet_id      = aws_subnet.app_subnet.id
  route_table_id = aws_route_table.app_route_table.id
}

resource "aws_internet_gateway" "app_internet_gateway" {
  tags = {
    "Name" = "app_internet_gateway"
  }
  vpc_id = aws_vpc.app_vpc.id
  depends_on = [
    aws_vpc.app_vpc
  ]
}

resource "aws_route" "app_route" {
  route_table_id         = aws_route_table.app_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.app_internet_gateway.id
}

resource "aws_security_group" "app_SG" {
  name        = "app_SG"
  description = "allow inbound and outbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

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

resource "tls_private_key" "web_key" {
  algorithm = "RSA"
}


resource "aws_key_pair" "APP_Instance_key" {
  key_name   = "web_key"
  public_key = tls_private_key.web_key.public_key_openssh
}

resource "local_file" "web_key" {
  content  = tls_private_key.web_key.private_key_pem
  filename = "web_key.pem"
}

resource "aws_instance" "web" {
  # count = 3
  ami                         = "ami-068257025f72f470d"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.app_subnet.id
  key_name                    = "web_key"
  security_groups             = [aws_security_group.app_SG.id]
  tags = {
    "Name" = "Webserver"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.web_key.private_key_pem
    host        = self.public_ip
  }


  provisioner "local-exec" {
    command = "echo ${aws_instance.web.public_ip} > instance-ip.txt"
  }

  provisioner "file" {
    source      = "./index.sh"
    destination = "/home/ubuntu/index.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sh /home/ubuntu/index.sh"
    ]
  }
}

