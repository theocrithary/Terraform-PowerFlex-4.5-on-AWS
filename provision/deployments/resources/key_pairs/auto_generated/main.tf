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
variable "key_path" {
  type = string
  description = "the base key path"
}
// Sends your public key to the instance
resource "aws_key_pair" "powerflex-denver-key" {
  key_name   = "${var.application_version}-key-${var.creator}-${var.timestamp}"
  public_key = file("${var.key_path}-${var.timestamp}.pub")
}
output "key-id" {
  description = "The ID of the co res key"
  value       =  try(aws_key_pair.powerflex-denver-key.id, "")
}