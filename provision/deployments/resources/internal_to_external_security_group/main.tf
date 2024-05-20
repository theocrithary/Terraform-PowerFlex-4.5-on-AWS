variable "vpc_id" {
  type = string
  description = "the vpc id"
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
variable "public_subnet_cidr" {
  type = string
  description = "the public cidr range"
}
resource "aws_security_group" "powerflex-access-between-internal-to-external-traffic" {
  vpc_id = var.vpc_id
  ingress {
    description = "DEV ONLY - HTTPs from proxy"
    from_port   = 443
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
    to_port     = 443
  }
  ingress {
    description = "DEV ONLY - Allow SSH from proxy"
    from_port   = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
    to_port     = 22
  }
  ingress {
    description = "DEV ONLY - NodePort access from proxy"
    from_port   = 30400
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
    to_port     = 30400
  }
  ingress {
    description = "DEV ONLY - HTTP from proxy"
    from_port   = 80
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
    to_port     = 80
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.application_version}-access-internal-to-external-${var.creator}-${var.timestamp}"
    GeneratedBy = "hashicorp terraform"
    Release     = var.application_version
    Creator     = var.creator
  }
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = try(aws_security_group.powerflex-access-between-internal-to-external-traffic.id, "")
}