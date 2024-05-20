
variable "vpc_cidr" {
  type = string
  description = "the vpc cidr range"
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
resource "aws_vpc" "powerflex-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  instance_tenancy     = "default"
  tags = {
    Name        = "${var.application_version}-vpc-${var.creator}-${var.timestamp}"
    GeneratedBy = "hashicorp terraform"
    Release     = var.application_version
    Creator     = var.creator
  }
}
output "vpc_id" {
  description = "The ID of the VPC"
  value       = try(aws_vpc.powerflex-vpc.id, "")
}