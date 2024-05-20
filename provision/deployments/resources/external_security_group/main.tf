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
resource "aws_security_group" "powerflex-allow-external-traffic" {
  vpc_id = var.vpc_id
  ingress {
    description = "Allow SSH"
    from_port   = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    to_port     = 22
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.application_version}-allow-external-traffic-${var.creator}-${var.timestamp}"
    GeneratedBy = "hashicorp terraform"
    Release     = var.application_version
    Creator     = var.creator
  }
}
output "security_group_id" {
  description = "The ID of the public security group"
  value       = try(aws_security_group.powerflex-allow-external-traffic.id, "")
}