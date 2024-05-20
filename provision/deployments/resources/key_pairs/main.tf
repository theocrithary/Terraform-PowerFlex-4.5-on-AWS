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
variable "keys" {
  type = map(string)
  description = "the paths for the private and public keys"
}
// Sends your public key to the instance
resource "aws_key_pair" "powerflex-denver-co-res-key" {
  key_name   = "${var.application_version}-co-res-key-${var.creator}-${var.timestamp}"
  public_key = file(lookup(var.keys, "co_res_public"))
}

resource "aws_key_pair" "powerflex-denver-installer-key" {
  key_name   = "${var.application_version}-installer-key-${var.creator}-${var.timestamp}"
  public_key = file(lookup(var.keys, "installer_public"))
}

resource "aws_key_pair" "powerflex-denver-proxy-key" {
  key_name   = "${var.application_version}-proxy-key-${var.creator}-${var.timestamp}"
  public_key = file(lookup(var.keys, "proxy_public"))
}

output "co-res-id" {
  description = "The ID of the co res key"
  value       =  try(aws_key_pair.powerflex-denver-co-res-key.id, "")
}

output "installer-id" {
  description = "The ID of the installer key"
  value       = try(aws_key_pair.powerflex-denver-installer-key.id, "")
}

output "proxy-id" {
  description = "The ID of the proxy key"
  value       = try(aws_key_pair.powerflex-denver-proxy-key.id, "")
}