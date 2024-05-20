variable "vpc_id" {
  type = string
  description = "the vpc id"
}

variable "private_subnet_cidr" {
  type = list(string)
  description = "the private cidr range"
}

variable "aws_storage_aw" {
  type = list(string)
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

variable "subnet_count" {
  type = number
  description = "the number of subnets - single az = 1 | multi az = 3"
}

resource "aws_subnet" "powerflex-subnet-private" {
  count = var.subnet_count
  vpc_id                  = var.vpc_id
  cidr_block              = var.private_subnet_cidr[count.index]
  map_public_ip_on_launch = "false" //it makes this a private subnet
  availability_zone       = var.aws_storage_aw[count.index]
  tags = {
    Name        = "${var.application_version}-subnet-private-${count.index + 1}-${var.creator}-${var.timestamp}"
    GeneratedBy = "hashicorp terraform"
    Release     = var.application_version
    Creator     = var.creator
    AZ = var.aws_storage_aw[count.index]
  }
}

output "subnet_ids" {
  description = "The id's of the private subnets"
  value       = aws_subnet.powerflex-subnet-private.*.id
}