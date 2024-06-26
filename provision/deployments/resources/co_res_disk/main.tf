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
variable "instance_count" {
  type = number
  description = "the number of co-res instances"
}
variable "disk_count" {
  type = number
  description = "the number of disks per instance"
}
variable "disk_size" {
  type = number
  description = "the size of each co-res disk"
  default = 5000
}
variable "aws_storage_az" {
  type = list(string)
  description = "the different availability zones list"
}

resource "aws_ebs_volume" "powerflex-co-res-volume" {
  count      = var.instance_count * var.disk_count
  size       = var.disk_size
  type       = "gp3"
  iops       = floor(40000/var.disk_count)
  throughput = 1000
  tags = {
    Name        = "${var.application_version}-co-res-volume-${count.index + 1}-${var.creator}-${var.timestamp}"
    GeneratedBy = "hashicorp terraform"
    Release     = var.application_version
    Creator     = var.creator
  }
  availability_zone = var.aws_storage_az[floor(count.index / var.disk_count) % length(var.aws_storage_az)]
}

output "volume_ids" {
  description = "The volume ids array"
  value       = aws_ebs_volume.powerflex-co-res-volume.*.id
}