variable "region" {}
variable "access_key" {}
variable "secret_key" {}

provider "aws" {
  region  = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

variable "web-open-ports" {
  type = list(number)
  default = [ 22,80,443 ]
}

resource "aws_vpc" "dev-vpc" {
  cidr_block = "10.10.0.0/22"
  tags = {
    "Name": "dev-vpc"
  } 
}

resource "aws_subnet" "dev-public-subnet" {
  depends_on = [
    aws_vpc.dev-vpc
  ]
  availability_zone = "ap-southeast-2a"
  vpc_id = aws_vpc.dev-vpc.id
  cidr_block = "10.10.0.0/22"
  tags = {
    "Name" = "dev-public-subnet"
  }
}

resource "aws_security_group" "my-security-group" {
  vpc_id = aws_vpc.dev-vpc.id
  name = "my-security-group"
  dynamic "ingress" { 
    for_each = var.web-open-ports
    iterator = port
    content {
      from_port = port.value
      to_port = port.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0e040c48614ad1327"
  instance_type = "t2.micro"
  depends_on = [
    aws_vpc.dev-vpc,
    aws_subnet.dev-public-subnet,
    aws_security_group.my-security-group
  ]
  tags = {
    Name = "ubuntu-srv-${count.index + 1}"
  }
  subnet_id = aws_subnet.dev-public-subnet.id
  count = 2
  security_groups = [ aws_security_group.my-security-group.id ]
}
