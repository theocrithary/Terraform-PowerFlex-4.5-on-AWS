data "aws_caller_identity" "current" {}
variable "aws_region" {
  default = "us-east-1"
}
variable "keys_path" {
  type    = string
  default = "../../../keys"
}
variable "key_path" {
  type    = string
  default = "../../../keys/powerflex-denver-key"
}
variable "ssh_keys_path" {
  type    = string
  default = "/var/pfmp/keys"
}
variable "aws_storage_az" {
  type    = list(string)
  default = ["us-east-1a"]
}
variable "ami" {
  type = map(string)
  default = {
    proxy     = "ami-073ed533d6681ffb9"
    co-res    = "ami-085e25c4320e48e22"
    installer = "ami-082522aee30d88d15"
  }
}
variable "instance_type" {
  type = map(string)
  default = {
    proxy     = "t2.micro"
    co-res    = "c5n.9xlarge"
    installer = "c5n.2xlarge"
  }
}
variable "cluster_node_port" {
  type    = string
  default = "30400"
}
variable "load_balancer_port" {
  type    = string
  default = "443"
}
variable "load_balancer_protocol" {
  type    = string
  default = "TCP"
}
variable "target_group_port" {
  type    = string
  default = "443"
}
variable "target_group_protocol" {
  type    = string
  default = "TCP"
}
variable "user" {
  type    = string
  default = "ec2-user"
}
variable "generated_username" {
  type    = string
  default = "pflex-user"
}
variable "co_res_count" {
  type    = number
  default = 3
}
variable "number_of_disks" {
  type    = number
  default = 3
}
variable "disk_size" {
  type    = number
  default = 500
}
locals {
  creator   = replace(replace(replace(regex("[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+", data.aws_caller_identity.current.arn), "@Dell.com", ""), "@emc.com", ""), ".", "")
  timestamp = replace(replace(replace(timestamp(), "Z", ""), ":", ""), "-", "")
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "private_subnet_cidr" {
  type    = list(string)
  default = ["10.0.1.0/27"]
}
variable "public_subnet_cidr" {
  type    = string
  default = "10.0.4.0/27"
}
variable "pods_cidr" {
  type    = string
  default = "10.42.0.0/16"
}
variable "application_version" {
  type    = string
  default = "powerflex-test-proxy"
}
variable "interpreter" {
  type    = list(string)
  default = ["C:\\Program Files\\Git\\bin\\bash.exe", "-c"]
}
variable "relative_location" {
  type    = string
  default = "/../../../proxy-mode/"
}
variable "run_new_installer_scripts_path" {
  type    = string
  default = "../resources/scripts/run_new_installer_api/scripts"
}
variable "csv_template_path" {
  type    = string
  default = "../resources/scripts/run_new_installer_api/csv_templates/5_co_res_5_disks.csv"
}