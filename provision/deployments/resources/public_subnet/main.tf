variable "vpc_id" {
  type = string
  description = "the vpc id"
}

variable "public_subnet_cidr" {
  type = string
  description = "the public cidr range"
}

variable "aws_storage_aw" {
  type = string
  description = "the availability zone of the selected resource"
}

variable "creator" {
  type = string
  description = "the script aws user initiator"
}
variable "timestamp" {
  type = string
  description = "the current timestamp"
}
variable "application_version" {
  type = string
  description = "the powerflex version name"
}

resource "aws_subnet" "powerflex-subnet-public" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = "true" // it makes this a public subnet
  availability_zone       = var.aws_storage_aw
  tags = {
    Name        = "${var.application_version}-subnet-public-${var.creator}-${var.timestamp}-DEV-ONLY"
    GeneratedBy = "hashicorp terraform"
    Release     = var.application_version
    Creator     = var.creator
  }
}

resource "aws_route_table" "powerflex-public-crt" {
  vpc_id = var.vpc_id
  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.powerflex-igw.id
  }
  tags = {
    Name        = "${var.application_version}-public-crt-${var.creator}-${var.timestamp}"
    GeneratedBy = "hashicorp terraform"
    Release     = var.application_version
    Creator     = var.creator
  }
}

resource "aws_internet_gateway" "powerflex-igw" {
  vpc_id = var.vpc_id
  tags = {
    Name        = "${var.application_version}-igw-${var.creator}-${var.timestamp}"
    GeneratedBy = "hashicorp terraform"
    Release     = var.application_version
    Creator     = var.creator
  }
}

resource "aws_route_table_association" "powerflex-crta-public-subnet" {
  subnet_id      = aws_subnet.powerflex-subnet-public.id
  route_table_id = aws_route_table.powerflex-public-crt.id
}

output "subnet_id" {
  description = "The ID of the public subnet id"
  value       = try(aws_subnet.powerflex-subnet-public.id, "")
}